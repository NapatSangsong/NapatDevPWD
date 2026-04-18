import Foundation
import CryptoKit
import Observation

@MainActor
@Observable
final class AppLockModel {
    enum State {
        case needsSetup
        case locked
        case unlocked
    }

    private(set) var state: State
    private(set) var key: SymmetricKey?

    /// Whether Face ID / Touch ID is enabled. Persisted.
    var biometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.biometricsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.biometricsKey) }
    }
    private static let biometricsKey = "napatdev.biometricsEnabled"

    var biometricsAvailable: Bool { BiometricAuth.available }
    var biometricKind: BiometricKind { BiometricAuth.kind }

    // MARK: - Auto-lock grace period

    /// Seconds after backgrounding before the vault locks. 0 = immediate.
    var autoLockSeconds: Int {
        get {
            UserDefaults.standard.object(forKey: Self.autoLockKey) == nil
                ? 0
                : UserDefaults.standard.integer(forKey: Self.autoLockKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.autoLockKey)
            pendingLockTask?.cancel()
            pendingLockTask = nil
        }
    }
    private static let autoLockKey = "napatdev.autoLockSeconds"

    private var pendingLockTask: Task<Void, Never>?

    // MARK: - Rate limiting

    private(set) var failedAttempts: Int = 0
    private(set) var lockedOutUntil: Date?

    var isRateLimited: Bool {
        guard let until = lockedOutUntil else { return false }
        return until > .now
    }

    var rateLimitRemaining: TimeInterval {
        guard let until = lockedOutUntil else { return 0 }
        return max(0, until.timeIntervalSinceNow)
    }

    private static let failedAttemptsKey = "napatdev.failedAttempts"
    private static let lockedUntilKey = "napatdev.lockedUntil"

    init() {
        self.state = MasterPassword.isConfigured ? .locked : .needsSetup
        self.failedAttempts = UserDefaults.standard.integer(forKey: Self.failedAttemptsKey)
        if let stamp = UserDefaults.standard.object(forKey: Self.lockedUntilKey) as? Date, stamp > .now {
            self.lockedOutUntil = stamp
        }
    }

    // MARK: - Setup / unlock / lock

    func setUp(password: String) throws {
        let key = try MasterPassword.setUp(password: password)
        self.key = key
        self.state = .unlocked
        resetRateLimit()
    }

    func unlock(password: String) throws {
        if isRateLimited {
            throw RateLimitError.tooManyAttempts(retryAfter: rateLimitRemaining)
        }
        do {
            let key = try MasterPassword.unlock(password: password)
            self.key = key
            self.state = .unlocked
            resetRateLimit()
            if biometricsEnabled && BiometricAuth.available {
                try? BiometricKeyStore.store(key)
            }
        } catch {
            recordFailedAttempt()
            throw error
        }
    }

    func unlockWithBiometrics(reason: String) async throws {
        let key = try await BiometricKeyStore.retrieve(reason: reason)
        self.key = key
        self.state = .unlocked
        resetRateLimit()
    }

    func lock() {
        pendingLockTask?.cancel()
        pendingLockTask = nil
        self.key = nil
        self.state = .locked
    }

    func fullReset() {
        MasterPassword.reset()
        BiometricKeyStore.delete()
        biometricsEnabled = false
        resetRateLimit()
        self.key = nil
        self.state = .needsSetup
    }

    // MARK: - Biometrics on/off

    func enableBiometrics() throws {
        guard let key else { throw BiometricKeyStoreError.notEnrolled }
        try BiometricKeyStore.store(key)
        biometricsEnabled = true
    }

    func disableBiometrics() {
        BiometricKeyStore.delete()
        biometricsEnabled = false
    }

    /// After a successful restore, replace Keychain credentials and mark the
    /// vault unlocked with the backup's derived key. The caller is
    /// responsible for pushing the restored `VaultFile` into the store.
    func applyRestoredCredentials(key: SymmetricKey, salt: Data, verifier: Data) {
        KeychainStore.set(salt, for: .masterSalt)
        KeychainStore.set(verifier, for: .masterVerifier)
        BiometricKeyStore.delete()  // biometric slot is tied to the old key
        biometricsEnabled = false
        resetRateLimit()
        self.key = key
        self.state = .unlocked
    }

    // MARK: - Grace-period helpers (called from scenePhase observer)

    func scheduleAutoLock() {
        pendingLockTask?.cancel()
        let seconds = max(0, autoLockSeconds)
        if seconds == 0 {
            lock()
            return
        }
        pendingLockTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.lock() }
        }
    }

    func cancelScheduledLock() {
        pendingLockTask?.cancel()
        pendingLockTask = nil
    }

    // MARK: - Rate limit internals

    private func recordFailedAttempt() {
        failedAttempts += 1
        UserDefaults.standard.set(failedAttempts, forKey: Self.failedAttemptsKey)
        if let cooldown = cooldownFor(attempts: failedAttempts) {
            let until = Date().addingTimeInterval(cooldown)
            lockedOutUntil = until
            UserDefaults.standard.set(until, forKey: Self.lockedUntilKey)
        }
    }

    private func resetRateLimit() {
        failedAttempts = 0
        lockedOutUntil = nil
        UserDefaults.standard.removeObject(forKey: Self.failedAttemptsKey)
        UserDefaults.standard.removeObject(forKey: Self.lockedUntilKey)
    }

    /// Exponential-ish backoff: 5 wrong → 30s, 10 → 5min, 15 → 30min, 20+ → 1h.
    private func cooldownFor(attempts: Int) -> TimeInterval? {
        switch attempts {
        case 0..<5:  return nil
        case 5..<10: return 30
        case 10..<15: return 5 * 60
        case 15..<20: return 30 * 60
        default:     return 60 * 60
        }
    }
}

enum RateLimitError: LocalizedError {
    case tooManyAttempts(retryAfter: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .tooManyAttempts(let retryAfter):
            let secs = Int(retryAfter.rounded(.up))
            if secs < 60 { return "Too many attempts. Try again in \(secs)s." }
            let mins = Int((retryAfter / 60).rounded(.up))
            return "Too many attempts. Try again in \(mins) min."
        }
    }
}
