import Foundation
import Security
import LocalAuthentication
import CryptoKit

enum BiometricKeyStoreError: LocalizedError {
    case notEnrolled
    case cancelled
    case failed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notEnrolled: return "Biometrics are not enrolled on this device."
        case .cancelled:   return "Biometric authentication was cancelled."
        case .failed(let s): return "Keychain error \(s)."
        }
    }
}

/// Stores the AES-GCM master key so Touch ID can unlock the vault on
/// subsequent launches.
///
/// ### Why this doesn't use `SecAccessControl(.biometryCurrentSet)`
/// That's the "best-practice" iOS approach, but on macOS it returns
/// `errSecMissingEntitlement (-34018)` for ad-hoc-signed apps: the
/// `keychain-access-groups` entitlement required to back it is only granted
/// to apps signed with a paid Developer Program team.
///
/// Instead we use a two-step scheme suitable for a personal, locally-built
/// app:
///   1. Store the key in a normal Keychain item protected by
///      `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
///   2. Gate retrieval behind an explicit `LAContext.evaluatePolicy` call so
///      the user must present Touch ID / Face ID before we read the bytes.
///
/// Trade-off: another process running under the same user account could in
/// principle read the Keychain item without triggering a biometric prompt.
/// For a personal Mac that's an acceptable trade; anyone else running
/// processes as you has bigger problems.
enum BiometricKeyStore {
    private static let account = "com.napat.dev.biometricKey"
    private static let service = "com.napat.dev"

    static func store(_ key: SymmetricKey) throws {
        _ = delete()

        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String:        data,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricKeyStoreError.failed(status)
        }
    }

    static func retrieve(reason: String) async throws -> SymmetricKey {
        // Step 1: require a fresh biometric success.
        let context = LAContext()
        context.localizedReason = reason

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume()
                } else if let laError = error as? LAError, laError.code == .userCancel {
                    continuation.resume(throwing: BiometricKeyStoreError.cancelled)
                } else {
                    continuation.resume(throwing: BiometricKeyStoreError.cancelled)
                }
            }
        }

        // Step 2: biometrics succeeded — load the key bytes.
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw BiometricKeyStoreError.failed(status) }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            throw BiometricKeyStoreError.failed(status)
        default:
            throw BiometricKeyStoreError.failed(status)
        }
    }

    static var isStored: Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func delete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
