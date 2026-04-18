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

    init() {
        self.state = MasterPassword.isConfigured ? .locked : .needsSetup
    }

    // MARK: - Setup / unlock / lock

    func setUp(password: String) throws {
        let key = try MasterPassword.setUp(password: password)
        self.key = key
        self.state = .unlocked
    }

    func unlock(password: String) throws {
        let key = try MasterPassword.unlock(password: password)
        self.key = key
        self.state = .unlocked
        // If the user previously enabled biometrics, refresh the stored key
        // (it may have changed if they rotated the master password).
        if biometricsEnabled && BiometricAuth.available {
            try? BiometricKeyStore.store(key)
        }
    }

    func unlockWithBiometrics(reason: String) async throws {
        let key = try await BiometricKeyStore.retrieve(reason: reason)
        self.key = key
        self.state = .unlocked
    }

    func lock() {
        self.key = nil
        self.state = .locked
    }

    func fullReset() {
        MasterPassword.reset()
        BiometricKeyStore.delete()
        biometricsEnabled = false
        self.key = nil
        self.state = .needsSetup
    }

    // MARK: - Biometrics on/off

    /// Enable biometrics — requires the vault to currently be unlocked so we
    /// can stash the derived key in the biometric-protected Keychain slot.
    func enableBiometrics() throws {
        guard let key else { throw BiometricKeyStoreError.notEnrolled }
        try BiometricKeyStore.store(key)
        biometricsEnabled = true
    }

    func disableBiometrics() {
        BiometricKeyStore.delete()
        biometricsEnabled = false
    }
}
