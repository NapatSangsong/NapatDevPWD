import Foundation

/// Minimal URLSession-based Supabase REST client. We avoid the Swift SDK to
/// keep the dependency graph at zero — all we need is email+password auth,
/// a token refresh loop, and `vault_sync` upsert/select.
struct SupabaseClient {
    let baseURL: URL
    let publishableKey: String
    var session: SupabaseSession?

    init(baseURL: URL, publishableKey: String, session: SupabaseSession? = nil) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.session = session
    }

    // MARK: - Auth

    /// Sign up or sign in with email + password.
    func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await postAuth(path: "/auth/v1/token?grant_type=password", body: [
            "email": email,
            "password": password,
        ])
    }

    /// Create a new Supabase user with email + password. Sends a confirmation
    /// email if the project requires it; returns a session directly if not.
    func signUp(email: String, password: String) async throws -> SupabaseSession? {
        var req = try request(path: "/auth/v1/signup")
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.checkStatus(response, body: data)
        return try? JSONDecoder.supabase.decode(SupabaseSession.self, from: data)
    }

    func refresh(refreshToken: String) async throws -> SupabaseSession {
        try await postAuth(path: "/auth/v1/token?grant_type=refresh_token", body: [
            "refresh_token": refreshToken,
        ])
    }

    private func postAuth(path: String, body: [String: String]) async throws -> SupabaseSession {
        var req = try request(path: path)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.checkStatus(response, body: data)
        return try JSONDecoder.supabase.decode(SupabaseSession.self, from: data)
    }

    // MARK: - Vault sync table

    /// Fetch the current user's encrypted vault blob, or nil if none yet.
    func fetchVaultSync() async throws -> VaultSyncRow? {
        guard let session else { throw SupabaseError.notAuthenticated }
        var req = try request(path: "/rest/v1/vault_sync?select=*")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.checkStatus(response, body: data)
        let rows = try JSONDecoder.supabase.decode([VaultSyncRow].self, from: data)
        return rows.first
    }

    /// Upsert the current user's vault blob.
    func upsertVaultSync(_ row: VaultSyncRow) async throws {
        guard let session else { throw SupabaseError.notAuthenticated }
        var req = try request(path: "/rest/v1/vault_sync?on_conflict=user_id")
        req.httpMethod = "POST"
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        let encoder = JSONEncoder.supabase
        req.httpBody = try encoder.encode(row)
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.checkStatus(response, body: data)
    }

    // MARK: - Helpers

    private func request(path: String) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw SupabaseError.badURL
        }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.setValue(publishableKey, forHTTPHeaderField: "apikey")
        return req
    }

    private static func checkStatus(_ response: URLResponse, body: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard !(200..<300).contains(http.statusCode) else { return }
        let text = String(data: body, encoding: .utf8) ?? ""
        throw SupabaseError.badStatus(http.statusCode, text)
    }
}

// MARK: - Types

struct SupabaseSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresAt: Int64?
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case user
    }
}

struct SupabaseUser: Codable, Equatable {
    let id: String
    let email: String?
}

/// Row format in the `vault_sync` table. Bytea columns transit as base64
/// strings via PostgREST; we handle the conversion explicitly so Swift
/// Data lands on both sides.
struct VaultSyncRow: Codable {
    let userID: String
    let ciphertext: Data
    let salt: Data
    let verifier: Data
    let schemaVersion: Int
    let versionCounter: Int64?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case ciphertext
        case salt
        case verifier
        case schemaVersion = "schema_version"
        case versionCounter = "version_counter"
        case updatedAt = "updated_at"
    }

    init(userID: String, ciphertext: Data, salt: Data, verifier: Data,
         schemaVersion: Int = 1, versionCounter: Int64? = nil, updatedAt: String? = nil) {
        self.userID = userID
        self.ciphertext = ciphertext
        self.salt = salt
        self.verifier = verifier
        self.schemaVersion = schemaVersion
        self.versionCounter = versionCounter
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try c.decode(String.self, forKey: .userID)
        self.schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.versionCounter = try c.decodeIfPresent(Int64.self, forKey: .versionCounter)
        self.updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        self.ciphertext = try Self.decodeBytea(c, forKey: .ciphertext)
        self.salt       = try Self.decodeBytea(c, forKey: .salt)
        self.verifier   = try Self.decodeBytea(c, forKey: .verifier)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userID, forKey: .userID)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(Self.encodeBytea(ciphertext), forKey: .ciphertext)
        try c.encode(Self.encodeBytea(salt),       forKey: .salt)
        try c.encode(Self.encodeBytea(verifier),   forKey: .verifier)
        // version_counter + updated_at are server-managed; don't send.
    }

    private static func decodeBytea(_ c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Data {
        let raw = try c.decode(String.self, forKey: key)
        // PostgREST returns bytea as `\x<hex>` by default.
        if raw.hasPrefix("\\x") {
            let hex = String(raw.dropFirst(2))
            return Data(hexString: hex) ?? Data()
        }
        return Data(base64Encoded: raw) ?? Data()
    }

    private static func encodeBytea(_ data: Data) -> String {
        // PostgREST accepts bytea as `\x<hex>` on writes.
        "\\x" + data.map { String(format: "%02x", $0) }.joined()
    }
}

enum SupabaseError: LocalizedError {
    case badURL
    case notAuthenticated
    case badStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid Supabase URL."
        case .notAuthenticated: return "Not signed in to Supabase."
        case .badStatus(let code, let text):
            // Surface Supabase's error message if we can find it.
            if let data = text.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = obj["message"] as? String ?? obj["error_description"] as? String ?? obj["error"] as? String {
                return "Supabase (\(code)): \(msg)"
            }
            return "Supabase (\(code)): \(text)"
        }
    }
}

private extension JSONDecoder {
    static var supabase: JSONDecoder {
        let d = JSONDecoder()
        return d
    }
}

private extension JSONEncoder {
    static var supabase: JSONEncoder {
        let e = JSONEncoder()
        return e
    }
}

private extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            guard let b = UInt8(hexString[i..<j], radix: 16) else { return nil }
            data.append(b)
            i = j
        }
        self = data
    }
}
