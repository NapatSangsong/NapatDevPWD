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

    // MARK: - Tool loop (non-streaming — reliable path)

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

            let response = try await client.sendMessages(
                system: system,
                tools: AssistantTools.definitions,
                messages: apiMessages
            )
            usageSummary = formatUsage(response.usage)
            apiMessages.append(APIMessage(role: "assistant", content: response.content))

            // Surface text and collect tool calls.
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

    private func formatUsage(_ usage: MessagesResponse.Usage?) -> String? {
        guard let usage else { return nil }
        var parts: [String] = []
        if let inTokens = usage.inputTokens { parts.append("in:\(inTokens)") }
        if let outTokens = usage.outputTokens { parts.append("out:\(outTokens)") }
        if let cached = usage.cacheReadInputTokens, cached > 0 { parts.append("cache:\(cached)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
