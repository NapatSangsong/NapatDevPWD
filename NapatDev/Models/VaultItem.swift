import Foundation

/// One labelled environment URL — e.g. `label = "PRD"`, `url = "https://kms.pttgrp.com"`.
struct EnvironmentURL: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String = ""
    var url: String = ""

    init(id: UUID = UUID(), label: String = "", url: String = "") {
        self.id = id
        self.label = label
        self.url = url
    }

    /// Backward-compatible decoder so older vault files missing `id` still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id    = (try c.decodeIfPresent(UUID.self,   forKey: .id))    ?? UUID()
        self.label = (try c.decodeIfPresent(String.self, forKey: .label)) ?? ""
        self.url   = (try c.decodeIfPresent(String.self, forKey: .url))   ?? ""
    }
}

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
    /// Labelled per-environment URLs (e.g. PRD / DEV / UAT).
    var environments: [EnvironmentURL] = []
    /// Free-form tags (e.g. "PTT", "vpn", "work", "account"). Normalised to
    /// the case the user types; dedup happens at the UI level.
    var tags: [String] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        username: String = "",
        website: String = "",
        vaultID: UUID? = nil,
        brandSeed: String = "default",
        isFavorite: Bool = false,
        passkeyNote: String? = nil,
        password: String = "",
        notes: String = "",
        environments: [EnvironmentURL] = [],
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.username = username
        self.website = website
        self.vaultID = vaultID
        self.brandSeed = brandSeed
        self.isFavorite = isFavorite
        self.passkeyNote = passkeyNote
        self.password = password
        self.notes = notes
        self.environments = environments
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Forward-compatible: any missing key falls back to the default value so
    /// old on-disk vault files keep loading when we add new fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id           = (try c.decodeIfPresent(UUID.self,              forKey: .id))           ?? UUID()
        self.title        = (try c.decodeIfPresent(String.self,            forKey: .title))        ?? ""
        self.username     = (try c.decodeIfPresent(String.self,            forKey: .username))     ?? ""
        self.website      = (try c.decodeIfPresent(String.self,            forKey: .website))      ?? ""
        self.vaultID      =  try c.decodeIfPresent(UUID.self,              forKey: .vaultID)
        self.brandSeed    = (try c.decodeIfPresent(String.self,            forKey: .brandSeed))    ?? "default"
        self.isFavorite   = (try c.decodeIfPresent(Bool.self,              forKey: .isFavorite))   ?? false
        self.passkeyNote  =  try c.decodeIfPresent(String.self,            forKey: .passkeyNote)
        self.password     = (try c.decodeIfPresent(String.self,            forKey: .password))     ?? ""
        self.notes        = (try c.decodeIfPresent(String.self,            forKey: .notes))        ?? ""
        self.createdAt    = (try c.decodeIfPresent(Date.self,              forKey: .createdAt))    ?? .now
        self.updatedAt    = (try c.decodeIfPresent(Date.self,              forKey: .updatedAt))    ?? .now
        self.environments = (try c.decodeIfPresent([EnvironmentURL].self,  forKey: .environments)) ?? []
        self.tags         = (try c.decodeIfPresent([String].self,          forKey: .tags))         ?? []
    }

    var groupLetter: String {
        guard let first = title.first else { return "#" }
        let s = String(first).uppercased()
        return s.rangeOfCharacter(from: .letters) != nil ? s : "#"
    }
}
