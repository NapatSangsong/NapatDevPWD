import SwiftUI

struct ItemRow: View {
    let item: VaultItem
    var selected: Bool = false
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            BrandMark(seed: item.brandSeed, size: compact ? 26 : 30, radius: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.nd(13, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : DesignTokens.ink)
                    .lineLimit(1)
                Text(item.username.isEmpty ? "—" : item.username)
                    .font(.nd(11.5))
                    .foregroundStyle(selected ? Color.white.opacity(0.8) : DesignTokens.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : Color(hex: 0xF5A524))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            if selected {
                LinearGradient(
                    colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)],
                    startPoint: .top, endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: DesignTokens.accent.opacity(0.25), radius: 6, y: 2)
            }
        }
    }
}
