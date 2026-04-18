import SwiftUI

struct PasswordReveal: View {
    let password: String
    @State private var revealed = false
    @State private var didCopy = false

    private var strengthLabel: String {
        switch password.count {
        case 0..<8:     return "Weak"
        case 8..<12:    return "OK"
        case 12..<16:   return "Good"
        default:        return "Excellent"
        }
    }

    private var strengthColor: Color {
        switch password.count {
        case 0..<8:     return Color(hex: 0xE11D48)
        case 8..<12:    return Color(hex: 0xF5A524)
        case 12..<16:   return DesignTokens.accent
        default:        return DesignTokens.good
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(revealed ? password : String(repeating: "•", count: max(password.count, 8)))
                .font(.ndMono(13))
                .tracking(revealed ? 0 : 2)
                .foregroundStyle(DesignTokens.ink)
                .textSelection(.enabled)

            Button {
                revealed.toggle()
            } label: {
                Image(systemName: revealed ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.muted)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            Button {
                ClipboardManager.copy(password)
                didCopy = true
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    didCopy = false
                }
            } label: {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(didCopy ? DesignTokens.good : DesignTokens.muted)
                    .frame(width: 22, height: 22)
                    .background(DesignTokens.surface3, in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Text(strengthLabel)
                    .font(.nd(11.5, weight: .semibold))
                    .foregroundStyle(strengthColor)
                Circle()
                    .fill(strengthColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
    }
}
