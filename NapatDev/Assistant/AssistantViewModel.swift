import Foundation
import Observation

@MainActor
@Observable
final class AssistantViewModel {
    var turns: [ChatTurn] = []
    var proposals: [UUID: PendingProposal] = [:]
    var input: String = ""
    var isThinking: Bool = false
    var isConfigured: Bool { Secrets.anthropicAPIKey != nil }
    var usageSummary: String?

    /// User prompts in order — used for up-arrow recall.
    private(set) var promptHistory: [String] = []

    private var apiMessages: [APIMessage] = []
    private let store: VaultStore
    private let settings: AssistantSettings
    private let apiKey: String?
    private var currentTask: Task<Void, Never>?

    init(store: VaultStore, settings: AssistantSettings) {
        self.store = store
        self.settings = settings
        self.apiKey = Secrets.anthropicAPIKey
    }

    // MARK: - Public

    func reset() {
        cancelCurrentTask()
        turns = []
        proposals = [:]
        apiMessages = []
        usageSummary = nil
        promptHistory = []
    }

    /// Returns the most recent user prompt (for up-arrow recall).
    var lastPrompt: String? { promptHistory.last }

    func stop() {
        cancelCurrentTask()
    }

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // If something else is thinking, silently bail — but never while
        // claiming the UI flag. Clearer UX: cancel and replace.
        if isThinking { cancelCurrentTask() }
        input = ""

        guard apiKey != nil else {
            turns.append(ChatTurn(
                role: .system,
                text: "Set your Anthropic API key in Secrets.plist to use the assistant.",
                isError: true
            ))
            return
        }

        turns.append(ChatTurn(role: .user, text: text))
        apiMessages.append(APIMessage(role: "user", content: [.text(text)]))
        if promptHistory.last != text { promptHistory.append(text) }

        isThinking = true
        currentTask = Task { [weak self] in
            guard let self else { return }
            await self.runSafeToolLoop()
            await MainActor.run {
                self.isThinking = false
                self.currentTask = nil
            }
        }
    }

    func apply(proposal id: UUID) {
        guard var proposal = proposals[id], proposal.status == .pending else { return }
        switch proposal.kind {
        case .create(let item):
            store.upsert(item)
        case .update(_, let newItem, _):
            store.upsert(newItem)
        case .delete(let item):
            store.delete(item.id)
        }
        proposal.status = .applied
        proposals[id] = proposal
    }

    func cancel(proposal id: UUID) {
        guard var proposal = proposals[id], proposal.status == .pending else { return }
        proposal.status = .cancelled
        proposals[id] = proposal
    }

    // MARK: - Tool loop

    /// Outer wrapper that guarantees *any* failure surfaces in the chat and
    /// the UI state flag is reset. Catches both thrown errors and cancellation.
    private func runSafeToolLoop() async {
        do {
            try await runToolLoop()
        } catch is CancellationError {
            turns.append(ChatTurn(
                role: .system,
                text: "Stopped.",
                isError: false
            ))
        } catch {
            turns.append(ChatTurn(
                role: .system,
                text: error.localizedDescription,
                isError: true
            ))
        }
    }

    private func runToolLoop() async throws {
        guard let apiKey else { return }
        var client = AnthropicClient(apiKey: apiKey)
        client.model = settings.model.rawValue

        let system = [SystemBlock(
            text: AssistantTools.systemPrompt,
            cacheControl: CacheControl(type: "ephemeral")
        )]

        let dispatcher = AssistantToolDispatcher(store: store) { [weak self] proposal in
            self?.proposals[proposal.id] = proposal
            self?.turns.append(ChatTurn(
                role: .assistant,
                text: proposal.summary,
                proposalID: proposal.id
            ))
        }

        var iterations = 0
        let maxIterations = 5

        while iterations < maxIterations {
            try Task.checkCancellation()
            iterations += 1

            let response = try await client.sendMessages(
                system: system,
                tools: AssistantTools.definitions,
                messages: apiMessages
            )
            try Task.checkCancellation()

            usageSummary = formatUsage(response.usage)
            apiMessages.append(APIMessage(role: "assistant", content: response.content))

            var toolResults: [ContentBlock] = []
            for block in response.content {
                switch block {
                case .text(let text) where !text.isEmpty:
                    turns.append(ChatTurn(role: .assistant, text: text))
                case .text:
                    break
                case .toolUse(let id, let name, let input):
                    let (content, isError) = dispatcher.dispatch(name: name, input: input)
                    toolResults.append(.toolResult(toolUseId: id, content: content, isError: isError))
                case .toolResult:
                    break
                }
            }

            if response.stopReason == "tool_use", !toolResults.isEmpty {
                apiMessages.append(APIMessage(role: "user", content: toolResults))
                continue
            }
            break
        }
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        isThinking = false
    }

    private func formatUsage(_ usage: MessagesResponse.Usage?) -> String? {
        guard let usage else { return nil }
        var parts: [String] = []
        if let inTokens = usage.inputTokens { parts.append("in:\(inTokens)") }
        if let outTokens = usage.outputTokens { parts.append("out:\(outTokens)") }
        if let cached = usage.cacheReadInputTokens, cached > 0 { parts.append("cache:\(cached)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
