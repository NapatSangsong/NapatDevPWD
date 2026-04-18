import Foundation

struct VaultItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var username: String = ""
    var website: String = ""
    var vaultID: UUID?
    var brandSeed: String = "default"
    var isFavorite: Bool = false
    var passkeyNote: String?
    var password: String = ""
    var notes: String = ""
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var groupLetter: String {
        guard let first = title.first else { return "#" }
        let s = String(first).uppercased()
        return s.rangeOfCharacter(from: .letters) != nil ? s : "#"
    }
}
