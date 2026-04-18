import Foundation

/// Chat rendered to the user. Maps roughly to assistant/user turns + proposal
/// cards inlined between them.
struct ChatTurn: Identifiable {
    let id: UUID
    let role: Role
    let text: String
    let proposalID: UUID?
    let isError: Bool
    let createdAt: Date

    enum Role {
        case user, assistant, system
    }

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        proposalID: UUID? = nil,
        isError: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.proposalID = proposalID
        self.isError = isError
        self.createdAt = createdAt
    }
}

/// A staged edit that Claude has proposed. The user taps Apply to commit or
/// Cancel to drop it.
struct PendingProposal: Identifiable {
    let id: UUID
    let kind: Kind
    let createdAt: Date
    var status: Status = .pending

    enum Kind {
        case create(newItem: VaultItem)
        case update(oldItem: VaultItem, newItem: VaultItem, changedKeys: [String])
        case delete(item: VaultItem)
    }

    enum Status {
        case pending, applied, cancelled
    }

    var summary: String {
        switch kind {
        case .create(let item):
            return "Create \"\(item.title)\""
        case .update(_, let newItem, let changedKeys):
            let fields = changedKeys.sorted().joined(separator: ", ")
            return "Update \"\(newItem.title)\" (\(fields))"
        case .delete(let item):
            return "Delete \"\(item.title)\""
        }
    }
}
