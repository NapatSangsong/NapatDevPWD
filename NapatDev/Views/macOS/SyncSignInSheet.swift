#if os(macOS)
import SwiftUI

struct SyncSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SyncModel.self) private var sync

    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var submitting: Bool = false
    @FocusState private var focusedField: Field?

    enum Mode: String, CaseIterable, Identifiable {
        case signIn, signUp
        var id: Self { self }
        var label: String {
            switch self {
            case .signIn: return "Sign in"
            case .signUp: return "Create account"
            }
        }
    }

    enum Field: Hashable { case email, password }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            picker
            fields
            if let error {
                Text(error)
                    .font(.nd(11.5))
                    .foregroundStyle(Color(hex: 0xE11D48))
            }
            footer
        }
        .padding(22)
        .frame(width: 400)
        .onAppear { focusedField = .email }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mode == .signIn ? "Sign in to sync" : "Create a sync account")
                .font(.nd(17, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
            Text("Your vault is encrypted on this Mac with your master password. Only the ciphertext is ever sent to Supabase.")
                .font(.nd(11.5))
                .foregroundStyle(DesignTokens.muted)
        }
    }

    private var picker: some View {
        Picker("", selection: $mode) {
            ForEach(Mode.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var fields: some View {
        VStack(spacing: 10) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .password }
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .password)
                .onSubmit(submit)
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
            Spacer()
            Button(submitting ? "…" : mode.label, action: submit)
                .keyboardShortcut(.defaultAction)
                .disabled(submitting || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
        }
    }

    private func submit() {
        guard !submitting else { return }
        submitting = true
        error = nil
        Task { @MainActor in
            do {
                switch mode {
                case .signIn:
                    try await sync.signIn(email: email, password: password)
                case .signUp:
                    try await sync.signUp(email: email, password: password)
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            submitting = false
        }
    }
}
#endif
