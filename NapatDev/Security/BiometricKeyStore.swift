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

/// Stores the AES-GCM master key in the Keychain behind biometric access
/// control. The raw key bytes never leave the device; the user unlocks the
/// Keychain item with Face ID / Touch ID, we retrieve the bytes, rebuild the
/// `SymmetricKey` in memory, and wipe on lock.
enum BiometricKeyStore {
    private static let account = "com.napat.dev.biometricKey"
    private static let service = "com.napat.dev"

    static func store(_ key: SymmetricKey) throws {
        // Wipe any prior entry first so access control re-applies cleanly.
        _ = delete()

        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        ) else {
            throw BiometricKeyStoreError.notEnrolled
        }

        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecAttrAccessControl as String: access,
            kSecValueData as String:        data,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricKeyStoreError.failed(status)
        }
    }

    static func retrieve(reason: String) async throws -> SymmetricKey {
        let context = LAContext()
        context.localizedReason = reason

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
        ]

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                switch status {
                case errSecSuccess:
                    if let data = result as? Data {
                        continuation.resume(returning: SymmetricKey(data: data))
                    } else {
                        continuation.resume(throwing: BiometricKeyStoreError.failed(status))
                    }
                case errSecUserCanceled, errSecAuthFailed:
                    continuation.resume(throwing: BiometricKeyStoreError.cancelled)
                default:
                    continuation.resume(throwing: BiometricKeyStoreError.failed(status))
                }
            }
        }
    }

    static var isStored: Bool {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
            kSecReturnAttributes as String: true,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
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
