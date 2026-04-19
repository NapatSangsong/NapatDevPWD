import Foundation

/// Stores the Supabase refresh token in Keychain so the user only signs in
/// once. Access token lives in memory (short-lived, ~1 h).
enum SupabaseSessionStore {
    private static let service = "com.napat.dev.supabase"
    private static let account = "refresh_token"

    static func saveRefreshToken(_ token: String) {
        delete()
        guard let data = token.data(using: .utf8) else { return }
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String:   data,
        ]
        SecItemAdd(q as CFDictionary, nil)
    }

    static func loadRefreshToken() -> String? {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let s = String(data: data, encoding: .utf8)
        else { return nil }
        return s
    }

    static func delete() {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
    }
}
