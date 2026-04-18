import Foundation

struct Vault: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = "Personal"
    var iconSeed: String = "basin"
    var createdAt: Date = .now
}

struct VaultFile: Codable {
    var schemaVersion: Int = 1
    var vaults: [Vault] = [Vault(name: "Personal", iconSeed: "basin")]
    var items: [VaultItem] = []
    var updatedAt: Date = .now
}
