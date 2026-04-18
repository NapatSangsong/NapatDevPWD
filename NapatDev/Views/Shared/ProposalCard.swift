import SwiftUI

struct ProposalCard: View {
    let proposal: PendingProposal
    var onApply: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            diffBody
            if proposal.status == .pending {
                actionButtons
            } else {
                statusBadge
            }
        }
        .padding(14)
        .background(DesignTokens.cardSolid, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(DesignTokens.hairline, lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: kindIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(kindColor, in: RoundedRectangle(cornerRadius: 5))
            Text(kindLabel)
                .font(.nd(11, weight: .semibold))
                .foregroundStyle(DesignTokens.accentInk)
                .textCase(.uppercase)
                .tracking(0.4)
            Spacer()
            Text(proposal.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.nd(11))
                .foregroundStyle(DesignTokens.muted2)
        }
    }

    @ViewBuilder
    private var diffBody: some View {
        switch proposal.kind {
        case .create(let item):
            VStack(alignment: .leading, spacing: 4) {
                row("title", "—", item.title, isNew: true)
                if !item.username.isEmpty { row("username", "—", item.username, isNew: true) }
                if !item.website.isEmpty  { row("website", "—", item.website, isNew: true) }
                if !item.password.isEmpty { row("password", "—", "••••••••", isNew: true) }
            }
        case .update(let oldItem, let newItem, let changedKeys):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(changedKeys.sorted(), id: \.self) { key in
                    row(key,
                        oldValue(key, item: oldItem),
                        newValue(key, item: newItem))
                }
            }
        case .delete(let item):
            row("delete", item.title, "—", isDeletion: true)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.nd(12, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(DesignTokens.surface3, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onApply) {
                Text("Apply")
                    .font(.nd(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)],
                            startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: proposal.status == .applied ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(proposal.status == .applied ? DesignTokens.good : DesignTokens.muted)
            Text(proposal.status == .applied ? "Applied" : "Cancelled")
                .font(.nd(11, weight: .semibold))
                .foregroundStyle(DesignTokens.muted)
        }
    }

    private func row(_ label: String, _ oldValue: String, _ newValue: String, isNew: Bool = false, isDeletion: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.nd(11, weight: .semibold))
                .foregroundStyle(DesignTokens.accentInk)
                .frame(width: 68, alignment: .leading)
            if isNew {
                Text(newValue)
                    .font(.nd(12))
                    .foregroundStyle(DesignTokens.ink)
            } else if isDeletion {
                Text(oldValue)
                    .font(.nd(12))
                    .strikethrough()
                    .foregroundStyle(Color(hex: 0xE11D48))
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Text(oldValue)
                        .font(.nd(12))
                        .strikethrough()
                        .foregroundStyle(DesignTokens.muted)
                    Image(systemName: "arrow.right").font(.system(size: 9)).foregroundStyle(DesignTokens.muted2)
                    Text(newValue)
                        .font(.nd(12, weight: .semibold))
                        .foregroundStyle(DesignTokens.good)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func oldValue(_ key: String, item: VaultItem) -> String {
        switch key {
        case "title":      return item.title
        case "username":   return item.username
        case "password":   return "••••••••"
        case "website":    return item.website
        case "notes":      return item.notes.isEmpty ? "—" : item.notes
        case "brandSeed":  return item.brandSeed
        case "isFavorite": return "\(item.isFavorite)"
        default:           return "—"
        }
    }

    private func newValue(_ key: String, item: VaultItem) -> String {
        switch key {
        case "title":      return item.title
        case "username":   return item.username
        case "password":   return "••••••••"
        case "website":    return item.website
        case "notes":      return item.notes.isEmpty ? "—" : item.notes
        case "brandSeed":  return item.brandSeed
        case "isFavorite": return "\(item.isFavorite)"
        default:           return "—"
        }
    }

    private var kindLabel: String {
        switch proposal.kind {
        case .create: return "Create item"
        case .update: return "Update item"
        case .delete: return "Delete item"
        }
    }

    private var kindIcon: String {
        switch proposal.kind {
        case .create: return "plus"
        case .update: return "pencil"
        case .delete: return "trash"
        }
    }

    private var kindColor: Color {
        switch proposal.kind {
        case .create: return DesignTokens.good
        case .update: return DesignTokens.accent
        case .delete: return Color(hex: 0xE11D48)
        }
    }
}
