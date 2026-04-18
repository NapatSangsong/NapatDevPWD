import Foundation
import CommonCrypto
import CryptoKit

enum KeyDerivation {
    static let iterations: UInt32 = 600_000
    static let keyLength = 32
    static let saltLength = 16

    static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: saltLength)
        _ = SecRandomCopyBytes(kSecRandomDefault, saltLength, &bytes)
        return Data(bytes)
    }

    static func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let passwordBytes = Array(password.utf8)
        var derived = [UInt8](repeating: 0, count: keyLength)

        let status = salt.withUnsafeBytes { saltPtr -> Int32 in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordBytes, passwordBytes.count,
                saltPtr.bindMemory(to: UInt8.self).baseAddress, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                iterations,
                &derived, keyLength
            )
        }

        precondition(status == kCCSuccess, "PBKDF2 failed with status \(status)")
        return SymmetricKey(data: Data(derived))
    }
}
