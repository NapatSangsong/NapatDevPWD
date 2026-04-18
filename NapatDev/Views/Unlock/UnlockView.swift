import SwiftUI

struct UnlockView: View {
    @Environment(AppLockModel.self) private var lock
    @State private var password: String = ""
    @State private var error: String?
    @State private var attempting = false
    @FocusState private var focused: Bool

    private var biometricsOffered: Bool {
        lock.biometricsEnabled && lock.biometricsAvailable
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)
            iconBlock
            VStack(spacing: 4) {
                Text("Locked")
                    .font(.nd(22, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("Enter your master password to open the vault.")
                    .font(.nd(12.5))
                    .foregroundStyle(DesignTokens.muted)
            }

            SecureField("Master password", text: $password)
                .textFieldStyle(.plain)
                .font(.nd(14))
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(DesignTokens.cardSolid, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(DesignTokens.hairline, lineWidth: 0.5))
                .focused($focused)
                .onSubmit(submit)
                .padding(.horizontal, 24)
                #if canImport(UIKit)
                .textInputAutocapitalization(.never)
                #endif

            if let error {
                Text(error).font(.nd(12)).foregroundStyle(Color(hex: 0xE11D48))
            }

            Button(action: submit) {
                Text(attempting ? "Unlocking…" : "Unlock")
                    .font(.nd(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(password.isEmpty || attempting)
            .padding(.horizontal, 24)

            if biometricsOffered {
                Button { Task { await biometricUnlock() } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: lock.biometricKind.systemImage)
                            .font(.system(size: 16))
                        Text("Unlock with \(lock.biometricKind.label)")
                            .font(.nd(13, weight: .medium))
                    }
                    .foregroundStyle(DesignTokens.accent)
                }
                .buttonStyle(.plain)
                .disabled(attempting)
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
        .onAppear {
            focused = true
            if biometricsOffered {
                Task { await biometricUnlock() }
            }
        }
    }

    private func submit() {
        guard !password.isEmpty else { return }
        attempting = true
        error = nil
        Task { @MainActor in
            do {
                try lock.unlock(password: password)
            } catch let err as RateLimitError {
                self.error = err.errorDescription
                self.password = ""
            } catch {
                if lock.isRateLimited {
                    let secs = Int(lock.rateLimitRemaining.rounded(.up))
                    self.error = "Too many wrong attempts. Try again in \(secs)s."
                } else {
                    let left = max(0, 5 - lock.failedAttempts)
                    self.error = left > 0
                        ? "Incorrect master password. \(left) attempts before cooldown."
                        : "Incorrect master password."
                }
                self.password = ""
            }
            attempting = false
        }
    }

    private func biometricUnlock() async {
        attempting = true
        error = nil
        do {
            try await lock.unlockWithBiometrics(reason: "Unlock your Napat Dev vault")
        } catch BiometricKeyStoreError.cancelled {
            // Silent — user cancelled, they'll use the password.
        } catch {
            self.error = "Biometric unlock failed. Use your master password."
        }
        attempting = false
    }

    private var iconBlock: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: DesignTokens.accent.opacity(0.4), radius: 20, y: 8)
    }
}
