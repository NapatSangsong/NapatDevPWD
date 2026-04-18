import SwiftUI

struct OnboardingView: View {
    @Environment(AppLockModel.self) private var lock

    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var error: String?
    @State private var showPassword = false

    private var canContinue: Bool {
        password.count >= 8 && password == confirm
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            iconBlock
            VStack(spacing: 6) {
                Text("Welcome to Napat Dev")
                    .font(.nd(22, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("Choose a master password. It stays on your device — if you forget it, we can't recover your vault.")
                    .font(.nd(12.5))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 10) {
                passwordField($password, placeholder: "Master password")
                passwordField($confirm, placeholder: "Confirm password")
                Toggle(isOn: $showPassword) { Text("Show password").font(.nd(11.5)) }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(DesignTokens.accent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            if let error {
                Text(error).font(.nd(12)).foregroundStyle(Color(hex: 0xE11D48))
            }

            Button {
                submit()
            } label: {
                Text("Create Vault")
                    .font(.nd(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .shadow(color: DesignTokens.accent.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.5)
            .padding(.horizontal, 24)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    private func submit() {
        do {
            try lock.setUp(password: password)
        } catch {
            self.error = "Couldn't create vault: \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    private func passwordField(_ binding: Binding<String>, placeholder: String) -> some View {
        Group {
            if showPassword {
                TextField(placeholder, text: binding)
            } else {
                SecureField(placeholder, text: binding)
            }
        }
        .textFieldStyle(.plain)
        .font(.nd(14))
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(DesignTokens.cardSolid, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(DesignTokens.hairline, lineWidth: 0.5))
        #if canImport(UIKit)
        .autocapitalization(.none)
        .textInputAutocapitalization(.never)
        #endif
    }

    private var iconBlock: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "key.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: DesignTokens.accent.opacity(0.4), radius: 20, y: 8)
    }
}
