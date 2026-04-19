import Foundation

// MARK: - Public API

enum AnthropicError: LocalizedError {
    case missingAPIKey
    case transport(URLError)
    case badStatus(Int, String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Anthropic API key found in Secrets.plist."
        case .transport(let e):
            return "Network error: \(e.localizedDescription)"
        case .badStatus(let code, let body):
            return "Claude API returned \(code): \(body)"
        case .decoding(let e):
            return "Couldn't decode Claude's response: \(e.localizedDescription)"
        }
    }
}

struct AnthropicClient {
    var apiKey: String
    var model: String = "claude-haiku-4-5"
    var maxTokens: Int = 2048
    /// Hard ceiling per request — stops the UI from hanging forever if the
    /// upstream stalls.
    var requestTimeout: TimeInterval = 45

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    /// Non-streaming request — still used for fallback paths.
    func sendMessages(
        system: [SystemBlock],
        tools: [ToolDefinition],
        messages: [APIMessage]
    ) async throws -> MessagesResponse {
        let request = try buildRequest(system: system, tools: tools, messages: messages, stream: false)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let e as URLError {
            throw AnthropicError.transport(e)
        }
        try Self.checkStatus(response, body: data)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(MessagesResponse.self, from: data)
        } catch {
            throw AnthropicError.decoding(error)
        }
    }

    /// Streams deltas as they arrive. Yields `.textDelta` for every token of
    /// the assistant text; `.done` fires once the whole response is in with
    /// the assembled content blocks + stop reason + usage.
    func streamMessages(
        system: [SystemBlock],
        tools: [ToolDefinition],
        messages: [APIMessage]
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(
                        system: system, tools: tools, messages: messages, stream: true
                    )
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    // Status check: if non-2xx, collect body and throw.
                    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                        var body = Data()
                        for try await byte in bytes { body.append(byte) }
                        let text = String(data: body, encoding: .utf8) ?? ""
                        throw AnthropicError.badStatus(http.statusCode, text)
                    }

                    var parser = SSEParser()
                    var assembler = StreamAssembler()

                    for try await line in bytes.lines {
                        guard let event = parser.ingest(line) else { continue }
                        if let delta = assembler.consume(event: event) {
                            continuation.yield(delta)
                        }
                    }
                    continuation.yield(.done(
                        content: assembler.finalContent,
                        stopReason: assembler.stopReason,
                        usage: assembler.usage
                    ))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Internals

    private func buildRequest(
        system: [SystemBlock],
        tools: [ToolDefinition],
        messages: [APIMessage],
        stream: Bool
    ) throws -> URLRequest {
        var req = URLRequest(url: endpoint, timeoutInterval: requestTimeout)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body = MessagesRequest(
            model: model,
            maxTokens: maxTokens,
            stream: stream,
            system: system,
            tools: tools,
            messages: messages
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        req.httpBody = try encoder.encode(body)
        return req
    }

    private static func checkStatus(_ response: URLResponse, body: Data) throws {
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        guard (200...299).contains(status) else {
            let text = String(data: body, encoding: .utf8) ?? ""
            throw AnthropicError.badStatus(status, text)
        }
    }
}

// MARK: - Streaming events

enum StreamEvent {
    case textDelta(String)
    /// Emitted once the full response is assembled. `content` is the list of
    /// content blocks (text + tool_use) ready to append to the conversation.
    case done(content: [ContentBlock], stopReason: String?, usage: MessagesResponse.Usage?)
}

/// Parses an SSE byte stream line-by-line into event objects. Each SSE frame
/// looks like: `event: name\ndata: { ... }\n\n`. We join `data:` lines until
/// a blank line, then emit.
private struct SSEParser {
    private var currentEvent: String?
    private var dataLines: [String] = []

    mutating func ingest(_ line: String) -> SSEFrame? {
        if line.isEmpty {
            // End of frame.
            defer {
                currentEvent = nil
                dataLines.removeAll()
            }
            guard let name = currentEvent, !dataLines.isEmpty else { return nil }
            let data = dataLines.joined(separator: "\n")
            return SSEFrame(event: name, data: data)
        }
        if line.hasPrefix("event:") {
            currentEvent = line.dropFirst("event:".count).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("data:") {
            let trimmed = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
            dataLines.append(String(trimmed))
        }
        return nil
    }
}

private struct SSEFrame {
    let event: String
    let data: String
}

fileprivate enum PartialBlock {
    case text(String)
    case toolUse(id: String, name: String, jsonAccum: String)
}

/// Accumulates SSE frames into a full response: text/tool-use content blocks,
/// stop_reason, usage. Yields per-token text deltas as they arrive.
private struct StreamAssembler {
    private var blocks: [PartialBlock] = []
    var stopReason: String?
    var usage: MessagesResponse.Usage?

    var finalContent: [ContentBlock] {
        blocks.map { block in
            switch block {
            case .text(let t):
                return .text(t)
            case .toolUse(let id, let name, let json):
                let parsed = (try? JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))) ?? .object([:])
                return .toolUse(id: id, name: name, input: parsed)
            }
        }
    }

    mutating func consume(event frame: SSEFrame) -> StreamEvent? {
        guard let data = frame.data.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        switch frame.event {
        case "content_block_start":
            if let start = try? decoder.decode(ContentBlockStartEnvelope.self, from: data) {
                blocks.append(start.partial)
            }
        case "content_block_delta":
            if let delta = try? decoder.decode(ContentBlockDeltaEnvelope.self, from: data) {
                return apply(delta: delta)
            }
        case "content_block_stop":
            break
        case "message_delta":
            if let msg = try? decoder.decode(MessageDeltaEnvelope.self, from: data) {
                if let reason = msg.delta?.stop_reason { stopReason = reason }
                if let u = msg.usage { usage = usage?.merged(with: u) ?? u }
            }
        case "message_start":
            if let start = try? decoder.decode(MessageStartEnvelope.self, from: data) {
                usage = start.message.usage
            }
        default:
            break
        }
        return nil
    }

    private mutating func apply(delta: ContentBlockDeltaEnvelope) -> StreamEvent? {
        guard blocks.indices.contains(delta.index) else { return nil }
        switch (blocks[delta.index], delta.delta) {
        case (.text(let existing), .text(let piece)):
            blocks[delta.index] = .text(existing + piece)
            return .textDelta(piece)
        case (.toolUse(let id, let name, let accum), .inputJson(let piece)):
            blocks[delta.index] = .toolUse(id: id, name: name, jsonAccum: accum + piece)
            return nil
        default:
            return nil
        }
    }
}

// MARK: - Envelope decoders

private struct ContentBlockStartEnvelope: Decodable {
    let index: Int
    let contentBlock: Inner

    enum CodingKeys: String, CodingKey {
        case index
        case contentBlock = "content_block"
    }

    struct Inner: Decodable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
    }

    var partial: PartialBlock {
        switch contentBlock.type {
        case "text":
            return .text(contentBlock.text ?? "")
        case "tool_use":
            return .toolUse(id: contentBlock.id ?? "", name: contentBlock.name ?? "", jsonAccum: "")
        default:
            return .text("")
        }
    }
}

private struct ContentBlockDeltaEnvelope: Decodable {
    let index: Int
    let delta: Delta

    enum Delta: Decodable {
        case text(String)
        case inputJson(String)
        case other

        private enum CodingKeys: String, CodingKey {
            case type
            case text
            case partial_json
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let type = try c.decode(String.self, forKey: .type)
            switch type {
            case "text_delta":
                self = .text(try c.decode(String.self, forKey: .text))
            case "input_json_delta":
                self = .inputJson(try c.decode(String.self, forKey: .partial_json))
            default:
                self = .other
            }
        }
    }
}

private struct MessageDeltaEnvelope: Decodable {
    let delta: Delta?
    let usage: MessagesResponse.Usage?

    struct Delta: Decodable {
        let stop_reason: String?
    }
}

private struct MessageStartEnvelope: Decodable {
    let message: MessagesResponse
}

extension MessagesResponse.Usage {
    /// Merge partial usage from streaming (message_delta only reports output tokens).
    func merged(with other: MessagesResponse.Usage) -> MessagesResponse.Usage {
        MessagesResponse.Usage(
            inputTokens: other.inputTokens ?? inputTokens,
            outputTokens: other.outputTokens ?? outputTokens,
            cacheCreationInputTokens: other.cacheCreationInputTokens ?? cacheCreationInputTokens,
            cacheReadInputTokens: other.cacheReadInputTokens ?? cacheReadInputTokens
        )
    }
}

// MARK: - Request types

struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let stream: Bool
    let system: [SystemBlock]
    let tools: [ToolDefinition]
    let messages: [APIMessage]
}

struct SystemBlock: Encodable {
    let type: String = "text"
    let text: String
    var cacheControl: CacheControl?

    enum CodingKeys: String, CodingKey {
        case type, text
        case cacheControl = "cache_control"
    }
}

struct CacheControl: Encodable {
    let type: String // "ephemeral"
}

struct ToolDefinition: Encodable {
    let name: String
    let description: String
    let inputSchema: JSONValue

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

// MARK: - Conversation types

struct APIMessage: Codable {
    let role: String // "user" | "assistant"
    let content: [ContentBlock]
}

indirect enum ContentBlock: Codable {
    case text(String)
    case toolUse(id: String, name: String, input: JSONValue)
    case toolResult(toolUseId: String, content: String, isError: Bool)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case id, name, input
        case toolUseId = "tool_use_id"
        case content
        case isError = "is_error"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try c.decode(String.self, forKey: .text))
        case "tool_use":
            self = .toolUse(
                id: try c.decode(String.self, forKey: .id),
                name: try c.decode(String.self, forKey: .name),
                input: try c.decode(JSONValue.self, forKey: .input)
            )
        case "tool_result":
            self = .toolResult(
                toolUseId: try c.decode(String.self, forKey: .toolUseId),
                content: try c.decode(String.self, forKey: .content),
                isError: (try? c.decode(Bool.self, forKey: .isError)) ?? false
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: c,
                debugDescription: "Unknown content block type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try c.encode("text", forKey: .type)
            try c.encode(text, forKey: .text)
        case .toolUse(let id, let name, let input):
            try c.encode("tool_use", forKey: .type)
            try c.encode(id, forKey: .id)
            try c.encode(name, forKey: .name)
            try c.encode(input, forKey: .input)
        case .toolResult(let toolUseId, let content, let isError):
            try c.encode("tool_result", forKey: .type)
            try c.encode(toolUseId, forKey: .toolUseId)
            try c.encode(content, forKey: .content)
            if isError { try c.encode(true, forKey: .isError) }
        }
    }
}

// MARK: - Response types

struct MessagesResponse: Decodable {
    let id: String
    let role: String
    let content: [ContentBlock]
    let stopReason: String?
    let usage: Usage?

    struct Usage: Decodable {
        let inputTokens: Int?
        let outputTokens: Int?
        let cacheCreationInputTokens: Int?
        let cacheReadInputTokens: Int?
    }
}

// MARK: - JSONValue — type-erased JSON for tool inputs

enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(
            in: c,
            debugDescription: "Unknown JSON value"
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null:         try c.encodeNil()
        case .bool(let b):  try c.encode(b)
        case .int(let i):   try c.encode(i)
        case .double(let d):try c.encode(d)
        case .string(let s):try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o):try c.encode(o)
        }
    }

    // Convenience accessors
    var stringValue: String? { if case .string(let s) = self { return s } else { return nil } }
    var boolValue: Bool? { if case .bool(let b) = self { return b } else { return nil } }
    var intValue: Int? {
        switch self {
        case .int(let i): return i
        case .double(let d): return Int(d)
        default: return nil
        }
    }
    var objectValue: [String: JSONValue]? { if case .object(let o) = self { return o } else { return nil } }
}
