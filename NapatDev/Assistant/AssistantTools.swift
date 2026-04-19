import Foundation

/// Tool definitions sent to Claude + the client-side dispatcher that executes
/// them against the vault. `propose_*` tools never mutate — they create a
/// `PendingProposal` that the user reviews and applies in the UI.
enum AssistantTools {

    // MARK: - System prompt

    static let systemPrompt = """
    You are a helpful password-manager assistant inside the Napat Dev app.

    You help the user organize, update, and understand their personal vault. \
    Items you see may contain plaintext passwords. Do NOT repeat passwords \
    unless the user explicitly asks. Keep responses short and concrete.

    Items can carry multiple named-environment URLs (e.g. PRD, DEV/UAT, STAGING). \
    When the user asks to add an environment to an item, include it in the \
    `environments` array of `propose_update` or `propose_create`. Use concise \
    uppercase labels like "PRD", "DEV", "UAT", or "DEV/UAT". The `website` field \
    stays for a single primary URL when only one is needed.

    To change the vault, use one of the `propose_*` tools. Proposals are NEVER \
    applied automatically — the user must tap Apply in the UI. After calling a \
    propose tool, tell the user in one short sentence what you proposed.

    Use `generate_password` when the user wants a new password. Default to \
    length 20 with symbols unless the user specifies otherwise.

    When asked to find something, prefer `search_items` before asking the user \
    for clarification. Only ask when the query is genuinely ambiguous.
    """

    // MARK: - Tool definitions

    /// Array-of-objects schema reused by propose_create / propose_update.
    private static let environmentsSchema: JSONValue = .object([
        "type": .string("array"),
        "description": .string("Labelled per-environment URLs like PRD / DEV/UAT. Full list replaces the item's current environments."),
        "items": .object([
            "type": .string("object"),
            "properties": .object([
                "label": .object([
                    "type": .string("string"),
                    "description": .string("Short uppercase label like PRD, DEV, UAT, DEV/UAT, STAGING."),
                ]),
                "url": .object([
                    "type": .string("string"),
                    "description": .string("The URL for this environment, including scheme."),
                ]),
            ]),
            "required": .array([.string("label"), .string("url")]),
        ]),
    ])

    static let definitions: [ToolDefinition] = [
        ToolDefinition(
            name: "search_items",
            description: "Search the vault for items matching a query. Matches on title, username, and website. Returns up to 10 results.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Free-text search string. Empty string returns all items."),
                    ])
                ]),
                "required": .array([.string("query")]),
            ])
        ),
        ToolDefinition(
            name: "get_item",
            description: "Get the full details of a single vault item by ID, including the decrypted password.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "id": .object([
                        "type": .string("string"),
                        "description": .string("The item's UUID as returned by search_items."),
                    ])
                ]),
                "required": .array([.string("id")]),
            ])
        ),
        ToolDefinition(
            name: "propose_update",
            description: "Propose an update to an existing vault item. Only fields you include will change. Does NOT apply — the user must approve.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "id":         .object(["type": .string("string")]),
                    "title":      .object(["type": .string("string")]),
                    "username":   .object(["type": .string("string")]),
                    "password":   .object(["type": .string("string")]),
                    "website":    .object(["type": .string("string")]),
                    "notes":      .object(["type": .string("string")]),
                    "brandSeed":  .object(["type": .string("string")]),
                    "isFavorite": .object(["type": .string("boolean")]),
                    "environments": environmentsSchema,
                ]),
                "required": .array([.string("id")]),
            ])
        ),
        ToolDefinition(
            name: "propose_create",
            description: "Propose creating a new vault item. Does NOT apply — the user must approve.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "title":      .object(["type": .string("string")]),
                    "username":   .object(["type": .string("string")]),
                    "password":   .object(["type": .string("string")]),
                    "website":    .object(["type": .string("string")]),
                    "notes":      .object(["type": .string("string")]),
                    "brandSeed":  .object(["type": .string("string")]),
                    "isFavorite": .object(["type": .string("boolean")]),
                    "environments": environmentsSchema,
                ]),
                "required": .array([.string("title")]),
            ])
        ),
        ToolDefinition(
            name: "propose_delete",
            description: "Propose deleting a vault item. Does NOT apply — the user must approve.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "id": .object(["type": .string("string")])
                ]),
                "required": .array([.string("id")]),
            ])
        ),
        ToolDefinition(
            name: "generate_password",
            description: "Generate a secure random password. Default length 20. Includes symbols unless told otherwise.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "length":  .object(["type": .string("integer")]),
                    "symbols": .object(["type": .string("boolean")]),
                ]),
                "required": .array([]),
            ])
        ),
    ]
}

/// Executes tool calls against the vault store and emits proposals to the view
/// model. Read-only tools return data directly; `propose_*` tools stage a
/// `PendingProposal` and return a short confirmation string to Claude.
@MainActor
struct AssistantToolDispatcher {
    let store: VaultStore
    /// Called when a propose_* tool stages a proposal.
    let stageProposal: (PendingProposal) -> Void

    func dispatch(name: String, input: JSONValue) -> (content: String, isError: Bool) {
        switch name {
        case "search_items":      return searchItems(input)
        case "get_item":          return getItem(input)
        case "propose_update":    return proposeUpdate(input)
        case "propose_create":    return proposeCreate(input)
        case "propose_delete":    return proposeDelete(input)
        case "generate_password": return generatePassword(input)
        default:
            return ("Unknown tool: \(name)", true)
        }
    }

    // MARK: - Read-only tools

    private func searchItems(_ input: JSONValue) -> (String, Bool) {
        let q = (input.objectValue?["query"]?.stringValue ?? "").lowercased()
        let matched = store.items
            .filter { item in
                q.isEmpty ||
                item.title.lowercased().contains(q) ||
                item.username.lowercased().contains(q) ||
                item.website.lowercased().contains(q)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .prefix(10)

        let rows = matched.map { item -> String in
            "- id=\(item.id.uuidString) · title=\"\(item.title)\" · username=\"\(item.username)\" · website=\"\(item.website)\" · favorite=\(item.isFavorite)"
        }
        if rows.isEmpty {
            return ("No items match \"\(q)\".", false)
        }
        return (rows.joined(separator: "\n"), false)
    }

    private func getItem(_ input: JSONValue) -> (String, Bool) {
        guard
            let idStr = input.objectValue?["id"]?.stringValue,
            let id = UUID(uuidString: idStr),
            let item = store.items.first(where: { $0.id == id })
        else {
            return ("No item with that ID.", true)
        }
        let lines = [
            "id: \(item.id.uuidString)",
            "title: \(item.title)",
            "username: \(item.username)",
            "password: \(item.password)",
            "website: \(item.website)",
            "notes: \(item.notes)",
            "brandSeed: \(item.brandSeed)",
            "isFavorite: \(item.isFavorite)",
            "updatedAt: \(item.updatedAt.ISO8601Format())",
        ]
        return (lines.joined(separator: "\n"), false)
    }

    // MARK: - Proposal tools (never mutate directly)

    private func proposeUpdate(_ input: JSONValue) -> (String, Bool) {
        guard
            let obj = input.objectValue,
            let idStr = obj["id"]?.stringValue,
            let id = UUID(uuidString: idStr),
            let current = store.items.first(where: { $0.id == id })
        else {
            return ("Couldn't find that item to update.", true)
        }

        var updated = current
        var changes: [String: (String, String)] = [:]
        func setField(_ key: String, _ newValue: String, _ apply: (inout VaultItem) -> Void, current: String) {
            if newValue != current {
                changes[key] = (current, newValue)
                apply(&updated)
            }
        }

        if let v = obj["title"]?.stringValue    { setField("title", v, { $0.title = v }, current: current.title) }
        if let v = obj["username"]?.stringValue { setField("username", v, { $0.username = v }, current: current.username) }
        if let v = obj["password"]?.stringValue { setField("password", v, { $0.password = v }, current: current.password) }
        if let v = obj["website"]?.stringValue  { setField("website", v, { $0.website = v }, current: current.website) }
        if let v = obj["notes"]?.stringValue    { setField("notes", v, { $0.notes = v }, current: current.notes) }
        if let v = obj["brandSeed"]?.stringValue{ setField("brandSeed", v, { $0.brandSeed = v }, current: current.brandSeed) }
        if let v = obj["isFavorite"]?.boolValue {
            if v != current.isFavorite {
                changes["isFavorite"] = ("\(current.isFavorite)", "\(v)")
                updated.isFavorite = v
            }
        }
        if let raw = obj["environments"],
           case .array(let arr) = raw {
            let parsed = arr.compactMap { envEntry -> EnvironmentURL? in
                guard let o = envEntry.objectValue,
                      let label = o["label"]?.stringValue,
                      let url = o["url"]?.stringValue
                else { return nil }
                return EnvironmentURL(label: label, url: url)
            }
            if parsed != current.environments {
                let oldSummary = current.environments.map { "\($0.label)=\($0.url)" }.joined(separator: ", ")
                let newSummary = parsed.map { "\($0.label)=\($0.url)" }.joined(separator: ", ")
                changes["environments"] = (oldSummary.isEmpty ? "—" : oldSummary,
                                           newSummary.isEmpty ? "—" : newSummary)
                updated.environments = parsed
            }
        }

        if changes.isEmpty {
            return ("The proposed update is identical to the current item — nothing to change.", false)
        }

        let proposal = PendingProposal(
            id: UUID(),
            kind: .update(oldItem: current, newItem: updated, changedKeys: Array(changes.keys)),
            createdAt: .now
        )
        stageProposal(proposal)
        let summary = changes.keys.sorted().joined(separator: ", ")
        return ("Proposal staged. The user will see it in the UI. Changes: \(summary).", false)
    }

    private func proposeCreate(_ input: JSONValue) -> (String, Bool) {
        guard
            let obj = input.objectValue,
            let title = obj["title"]?.stringValue, !title.isEmpty
        else {
            return ("A title is required to create an item.", true)
        }
        var envs: [EnvironmentURL] = []
        if let raw = obj["environments"], case .array(let arr) = raw {
            envs = arr.compactMap { envEntry in
                guard let o = envEntry.objectValue,
                      let label = o["label"]?.stringValue,
                      let url = o["url"]?.stringValue
                else { return nil }
                return EnvironmentURL(label: label, url: url)
            }
        }
        let item = VaultItem(
            title: title,
            username: obj["username"]?.stringValue ?? "",
            website: obj["website"]?.stringValue ?? "",
            brandSeed: obj["brandSeed"]?.stringValue ?? "default",
            isFavorite: obj["isFavorite"]?.boolValue ?? false,
            password: obj["password"]?.stringValue ?? "",
            notes: obj["notes"]?.stringValue ?? "",
            environments: envs
        )
        let proposal = PendingProposal(
            id: UUID(),
            kind: .create(newItem: item),
            createdAt: .now
        )
        stageProposal(proposal)
        return ("Proposal staged to create \"\(title)\". The user will review and apply.", false)
    }

    private func proposeDelete(_ input: JSONValue) -> (String, Bool) {
        guard
            let idStr = input.objectValue?["id"]?.stringValue,
            let id = UUID(uuidString: idStr),
            let item = store.items.first(where: { $0.id == id })
        else {
            return ("Couldn't find that item to delete.", true)
        }
        let proposal = PendingProposal(
            id: UUID(),
            kind: .delete(item: item),
            createdAt: .now
        )
        stageProposal(proposal)
        return ("Proposal staged to delete \"\(item.title)\". The user will review and apply.", false)
    }

    // MARK: - Password generator

    private func generatePassword(_ input: JSONValue) -> (String, Bool) {
        let length = input.objectValue?["length"]?.intValue ?? 20
        let symbols = input.objectValue?["symbols"]?.boolValue ?? true
        let pw = PasswordGenerator.generate(length: max(8, min(length, 128)), includeSymbols: symbols)
        return ("Generated password: \(pw)", false)
    }
}

enum PasswordGenerator {
    static func generate(length: Int, includeSymbols: Bool) -> String {
        let lower = "abcdefghijkmnopqrstuvwxyz"
        let upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        let digits = "23456789"
        let symbols = "!@#$%^&*()-_=+[]{}"
        var alphabet = lower + upper + digits
        if includeSymbols { alphabet += symbols }
        let chars = Array(alphabet)
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
