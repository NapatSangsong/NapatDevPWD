import Foundation
import Observation

@MainActor
@Observable
final class AssistantViewModel {
    var turns: [ChatTurn] = []
    var proposals: [UUID: PendingProposal] = [:]
    var input: String = ""
    var isThinking: Bool = false
    var streamingID: UUID?
    var isConfigured: Bool { Secrets.anthropicAPIKey != nil }
    var usageSummary: String?

    private var apiMessages: [APIMessage] = []
    private let store: VaultStore
    private let client: AnthropicClient?

    init(store: VaultStore) {
        self.store = store
        if let key = Secrets.anthropicAPIKey {
            self.client = AnthropicClient(apiKey: key)
        } else {
            self.client = nil
        }
    }

    // MARK: - Public

    func reset() {
        turns = []
        proposals = [:]
        apiMessages = []
        usageSummary = nil
        streamingID = nil
    }

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        input = ""

        guard let client else {
            turns.append(ChatTurn(
                role: .system,
                text: "Set your Anthropic API key in Secrets.plist to use the assistant.",
                isError: true
            ))
            return
        }

        turns.append(ChatTurn(role: .user, text: text))
        apiMessages.append(APIMessage(role: "user", content: [.text(text)]))

        isThinking = true
        defer { isThinking = false; streamingID = nil }

        do {
            try await runToolLoop(client: client)
        } catch {
            turns.append(ChatTurn(
                role: .system,
                text: error.localizedDescription,
                isError: true
            ))
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

    // MARK: - Streaming tool loop

    private func runToolLoop(client: AnthropicClient) async throws {
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
            iterations += 1

            // Start a new streaming turn; create a placeholder bubble we'll
            // append deltas into.
            let streamingTurnID = UUID()
            turns.append(ChatTurn(id: streamingTurnID, role: .assistant, text: ""))
            streamingID = streamingTurnID

            var finalContent: [ContentBlock] = []
            var stopReason: String?
            var usage: MessagesResponse.Usage?

            let stream = client.streamMessages(
                system: system,
                tools: AssistantTools.definitions,
                messages: apiMessages
            )
            for try await event in stream {
                switch event {
                case .textDelta(let piece):
                    if let idx = turns.firstIndex(where: { $0.id == streamingTurnID }) {
                        turns[idx] = ChatTurn(
                            id: streamingTurnID,
                            role: .assistant,
                            text: turns[idx].text + piece,
                            createdAt: turns[idx].createdAt
                        )
                    }
                case .done(let content, let reason, let u):
                    finalContent = content
                    stopReason = reason
                    usage = u
                }
            }

            // If the placeholder ended up empty (e.g. only tool_use blocks),
            // remove it so the UI doesn't show a blank bubble.
            if let idx = turns.firstIndex(where: { $0.id == streamingTurnID }),
               turns[idx].text.isEmpty {
                turns.remove(at: idx)
            }
            streamingID = nil
            usageSummary = formatUsage(usage)
            apiMessages.append(APIMessage(role: "assistant", content: finalContent))

            // Dispatch any tool_use blocks, collect results.
            var toolResults: [ContentBlock] = []
            for block in finalContent {
                if case .toolUse(let id, let name, let input) = block {
                    let (content, isError) = dispatcher.dispatch(name: name, input: input)
                    toolResults.append(.toolResult(toolUseId: id, content: content, isError: isError))
                }
            }

            if stopReason == "tool_use", !toolResults.isEmpty {
                apiMessages.append(APIMessage(role: "user", content: toolResults))
                continue
            }
            break
        }
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
