import Foundation
import CryptoKit
import Observation

/// Orchestrates the Mac-side half of E2E-encrypted vault sync via Supabase.
/// Responsibilities:
///   - Hold Supabase session (or nil if not signed in / sync disabled)
///   - On vault change: encrypt + push the blob
///   - On launch: pull the blob, verify the master password against the
///     stored `verifier`, decrypt, and hand it to `VaultStore`.
@MainActor
@Observable
final class SyncModel {
    enum Status: Equatable {
        case disabled       // No Supabase URL / key configured
        case signedOut
        case signedIn(email: String)
        case syncing
        case error(String)
    }

    private(set) var status: Status = .disabled
    private(set) var lastSyncedAt: Date?

    private var client: SupabaseClient?
    private var pushTask: Task<Void, Never>?

    init() {
        guard
            let urlString = Secrets.supabaseURL,
            let url = URL(string: urlString),
            let key = Secrets.supabasePublishableKey
        else {
            status = .disabled
            return
        }
        self.client = SupabaseClient(baseURL: url, publishableKey: key)
        status = .signedOut

        // Restore session from Keychain if present.
        if let refresh = SupabaseSessionStore.loadRefreshToken() {
            Task { await restore(refreshToken: refresh) }
        }
    }

    var isConfigured: Bool {
        if case .disabled = status { return false }
        return true
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        guard let client else { throw SupabaseError.badURL }
        status = .syncing
        do {
            let session = try await client.signIn(email: email, password: password)
            self.client?.session = session
            SupabaseSessionStore.saveRefreshToken(session.refreshToken)
            status = .signedIn(email: session.user.email ?? email)
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    func signUp(email: String, password: String) async throws {
        guard let client else { throw SupabaseError.badURL }
        status = .syncing
        do {
            if let session = try await client.signUp(email: email, password: password) {
                self.client?.session = session
                SupabaseSessionStore.saveRefreshToken(session.refreshToken)
                status = .signedIn(email: session.user.email ?? email)
            } else {
                status = .signedOut
                throw SyncError.emailConfirmationRequired
            }
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    func signOut() {
        SupabaseSessionStore.delete()
        client?.session = nil
        status = .signedOut
    }

    private func restore(refreshToken: String) async {
        guard let client else { return }
        do {
            let session = try await client.refresh(refreshToken: refreshToken)
            self.client?.session = session
            SupabaseSessionStore.saveRefreshToken(session.refreshToken)
            status = .signedIn(email: session.user.email ?? "signed in")
        } catch {
            // Stale token, fall back to signed-out.
            SupabaseSessionStore.delete()
            status = .signedOut
        }
    }

    // MARK: - Push / Pull

    /// Fetch the remote blob, if any, and try to decrypt it with the
    /// user-supplied master password. Returns the decoded VaultFile and the
    /// derived key on success.
    func pull(masterPassword: String) async throws -> (VaultFile, SymmetricKey)? {
        guard let client, client.session != nil else { return nil }
        guard let row = try await client.fetchVaultSync() else { return nil }

        let key = KeyDerivation.deriveKey(password: masterPassword, salt: row.salt)
        let verifierPlaintext: String
        do {
            verifierPlaintext = try Crypto.openString(row.verifier, key: key)
        } catch {
            throw SyncError.verifierMismatch
        }
        guard verifierPlaintext == MasterPassword.verifierPlaintext else {
            throw SyncError.verifierMismatch
        }

        let decrypted = try Crypto.open(row.ciphertext, key: key)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(VaultFile.self, from: decrypted)
        self.lastSyncedAt = .now
        return (file, key)
    }

    /// Encrypt `file` with `key` and push to Supabase.
    func push(file: VaultFile, key: SymmetricKey) {
        guard let client, let session = client.session else { return }
        pushTask?.cancel()
        pushTask = Task { [weak self] in
            do {
                guard
                    let salt = KeychainStore.get(.masterSalt),
                    let verifier = KeychainStore.get(.masterVerifier)
                else { return }

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.sortedKeys]
                let plain = try encoder.encode(file)
                let ciphertext = try Crypto.seal(plain, key: key)

                let row = VaultSyncRow(
                    userID: session.user.id,
                    ciphertext: ciphertext,
                    salt: salt,
                    verifier: verifier
                )
                try await client.upsertVaultSync(row)
                await MainActor.run { self?.lastSyncedAt = .now }
            } catch {
                await MainActor.run {
                    self?.status = .error("Sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

enum SyncError: LocalizedError {
    case emailConfirmationRequired
    case verifierMismatch

    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Check your email to confirm this account before signing in."
        case .verifierMismatch:
            return "Master password doesn't match the synced vault on this account."
        }
    }
}
