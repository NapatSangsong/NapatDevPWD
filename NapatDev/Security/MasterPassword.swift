import Foundation
import CryptoKit

enum MasterPasswordError: Error {
    case incorrectPassword
    case notSetUp
}

enum MasterPassword {
    static let verifierPlaintext = "NapatDev-v1"

    static var isConfigured: Bool {
        KeychainStore.get(.masterSalt) != nil && KeychainStore.get(.masterVerifier) != nil
    }

    static func setUp(password: String) throws -> SymmetricKey {
        let salt = KeyDerivation.randomSalt()
        let key = KeyDerivation.deriveKey(password: password, salt: salt)
        let verifier = try Crypto.sealString(verifierPlaintext, key: key)
        KeychainStore.set(salt, for: .masterSalt)
        KeychainStore.set(verifier, for: .masterVerifier)
        return key
    }

    static func unlock(password: String) throws -> SymmetricKey {
        guard
            let salt = KeychainStore.get(.masterSalt),
            let verifier = KeychainStore.get(.masterVerifier)
        else { throw MasterPasswordError.notSetUp }

        let key = KeyDerivation.deriveKey(password: password, salt: salt)
        do {
            let decoded = try Crypto.openString(verifier, key: key)
            guard decoded == verifierPlaintext else { throw MasterPasswordError.incorrectPassword }
            return key
        } catch {
            throw MasterPasswordError.incorrectPassword
        }
    }

    static func reset() {
        KeychainStore.delete(for: .masterSalt)
        KeychainStore.delete(for: .masterVerifier)
    }
}
