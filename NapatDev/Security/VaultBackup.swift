import Foundation
import CryptoKit

/// Self-contained encrypted backup: one file you can AirDrop to a fresh Mac
/// and restore from. Carries its own salt + verifier so it doesn't depend on
/// the current Keychain contents.
///
/// File extension: `.napatvaultbackup`
/// Format: JSON with base64-encoded byte blobs.
struct VaultBackup: Codable {
    let schemaVersion: Int
    let createdAt: Date
    let salt: Data
    let verifier: Data
    let ciphertext: Data

    static let currentSchemaVersion = 1
    static let fileExtension = "napatvaultbackup"
}

enum VaultBackupError: LocalizedError {
    case noVaultLoaded
    case wrongPassword
    case malformed
    case ioFailure(Error)

    var errorDescription: String? {
        switch self {
        case .noVaultLoaded: return "Can't back up: no vault is currently loaded."
        case .wrongPassword: return "Incorrect master password for this backup."
        case .malformed:     return "This file isn't a valid Napat Dev backup."
        case .ioFailure(let e): return "File error: \(e.localizedDescription)"
        }
    }
}

enum VaultBackupIO {

    // MARK: - Export

    /// Produce a self-contained backup using the **current** in-memory key.
    /// Since the key already decrypts the current `VaultFile`, we just bundle
    /// the ciphertext alongside a fresh verifier + salt copy from Keychain.
    static func exportBackup(using file: VaultFile, key: SymmetricKey) throws -> Data {
        guard
            let salt = KeychainStore.get(.masterSalt),
            let verifier = KeychainStore.get(.masterVerifier)
        else {
            throw VaultBackupError.noVaultLoaded
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let plaintext = try encoder.encode(file)
        let ciphertext = try Crypto.seal(plaintext, key: key)

        let backup = VaultBackup(
            schemaVersion: VaultBackup.currentSchemaVersion,
            createdAt: .now,
            salt: salt,
            verifier: verifier,
            ciphertext: ciphertext
        )

        let outEncoder = JSONEncoder()
        outEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        outEncoder.dataEncodingStrategy = .base64
        outEncoder.dateEncodingStrategy = .iso8601
        return try outEncoder.encode(backup)
    }

    // MARK: - Import

    /// Decrypt a backup with a user-supplied master password. Returns the
    /// restored `VaultFile` plus the derived key. Caller is responsible for
    /// storing salt/verifier in Keychain and writing the vault file to disk.
    static func importBackup(_ data: Data, password: String) throws -> (VaultFile, SymmetricKey, Data, Data) {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .iso8601

        let backup: VaultBackup
        do {
            backup = try decoder.decode(VaultBackup.self, from: data)
        } catch {
            throw VaultBackupError.malformed
        }

        // Derive key from the *backup's* salt + the user's password.
        let key = KeyDerivation.deriveKey(password: password, salt: backup.salt)

        // Verify against the verifier baked into the backup.
        do {
            let plaintext = try Crypto.openString(backup.verifier, key: key)
            guard plaintext == MasterPassword.verifierPlaintext else {
                throw VaultBackupError.wrongPassword
            }
        } catch {
            throw VaultBackupError.wrongPassword
        }

        // Decrypt the vault contents.
        let vaultJSON: Data
        do {
            vaultJSON = try Crypto.open(backup.ciphertext, key: key)
        } catch {
            throw VaultBackupError.malformed
        }

        let fileDecoder = JSONDecoder()
        fileDecoder.dateDecodingStrategy = .iso8601
        let file = try fileDecoder.decode(VaultFile.self, from: vaultJSON)

        return (file, key, backup.salt, backup.verifier)
    }
}
