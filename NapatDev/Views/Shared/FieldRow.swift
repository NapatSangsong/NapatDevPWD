import SwiftUI

struct FieldRow<Trailing: View>: View {
    let label: String
    let value: String
    var copyable: Bool = false
    var isLink: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.nd(11.5, weight: .semibold))
                .foregroundStyle(DesignTokens.accentInk)
            HStack(spacing: 8) {
                Text(value)
                    .font(.nd(13))
                    .foregroundStyle(isLink ? DesignTokens.accent : DesignTokens.ink)
                    .underline(isLink)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
                trailing()
                if copyable { copyButton }
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.hairline).frame(height: 0.5)
        }
    }

    private var copyButton: some View {
        Button {
            ClipboardManager.copy(value)
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
    }
}

extension FieldRow where Trailing == EmptyView {
    init(label: String, value: String, copyable: Bool = false, isLink: Bool = false) {
        self.init(label: label, value: value, copyable: copyable, isLink: isLink, trailing: { EmptyView() })
    }
}

