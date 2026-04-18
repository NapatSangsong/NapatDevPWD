import Foundation
import CryptoKit

enum CryptoError: Error {
    case encryptionFailed
    case decryptionFailed
}

enum Crypto {
    static func seal(_ plaintext: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key)
            guard let combined = sealed.combined else { throw CryptoError.encryptionFailed }
            return combined
        } catch {
            throw CryptoError.encryptionFailed
        }
    }

    static func open(_ ciphertext: Data, key: SymmetricKey) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: ciphertext)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw CryptoError.decryptionFailed
        }
    }

    static func sealString(_ string: String, key: SymmetricKey) throws -> Data {
        try seal(Data(string.utf8), key: key)
    }

    static func openString(_ ciphertext: Data, key: SymmetricKey) throws -> String {
        let data = try open(ciphertext, key: key)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
