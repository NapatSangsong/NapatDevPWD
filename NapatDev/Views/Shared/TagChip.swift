import SwiftUI

struct TagChip: View {
    let text: String
    var selected: Bool = false
    var onDelete: (() -> Void)? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.nd(11, weight: .semibold))
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .padding(.leading, 2)
            }
        }
        .foregroundStyle(selected ? .white : DesignTokens.accentInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(selected ? DesignTokens.accent : DesignTokens.accentSoft)
        )
        .contentShape(Capsule())
        .onTapGesture { action?() }
    }
}

/// Inline tag editor: existing chips + a comma-/return-separated input.
struct TagEditor: View {
    @Binding var tags: [String]
    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(text: tag, onDelete: {
                            tags.removeAll { $0 == tag }
                        })
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "number")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                TextField("Add tag and press return", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.nd(12))
                    .focused($focused)
                    .onSubmit(commit)
                    #if canImport(UIKit)
                    .autocapitalization(.allCharacters)
                    #endif
                if !draft.isEmpty {
                    Button("Add", action: commit)
                        .controlSize(.small)
                        .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(DesignTokens.surface3, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func commit() {
        // Accept both comma-separated "a, b, c" and single entries.
        let parts = draft
            .split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for part in parts where !tags.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
            tags.append(part)
        }
        draft = ""
        focused = true
    }
}

/// Minimal flow-wrap layout so tag chips can span multiple rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
