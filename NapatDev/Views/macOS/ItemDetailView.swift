#if os(macOS)
import SwiftUI

struct ItemDetailView: View {
    let item: VaultItem
    var onEdit: () -> Void

    @Environment(VaultStore.self) private var store
    @Environment(TagFilterModel.self) private var tagFilter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 8)
                if !item.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                selected: tagFilter.selected == tag
                            ) { tagFilter.toggle(tag) }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
                }

                VStack(spacing: 0) {
                    FieldRow(label: "username", value: item.username, copyable: !item.username.isEmpty)
                    FieldRow(label: "password", value: "") {
                        PasswordReveal(password: item.password)
                    }
                    if let passkey = item.passkeyNote {
                        FieldRow(label: "passkey", value: passkey)
                    }
                    if !item.website.isEmpty {
                        FieldRow(label: "website", value: item.website, copyable: true, isLink: true)
                    }
                    ForEach(item.environments) { env in
                        FieldRow(
                            label: env.label.isEmpty ? "env" : env.label.lowercased(),
                            value: env.url,
                            copyable: !env.url.isEmpty,
                            isLink: !env.url.isEmpty
                        )
                    }
                    if !item.notes.isEmpty {
                        FieldRow(label: "notes", value: item.notes)
                    }
                }
                .padding(.horizontal, 28)

                HStack(spacing: 6) {
                    Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(DesignTokens.muted)
                    Text("Last edited \(item.updatedAt.formatted(date: .long, time: .shortened))")
                        .font(.nd(12))
                        .foregroundStyle(DesignTokens.muted)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .background(DesignTokens.cardSolid)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { store.toggleFavorite(item.id) } label: {
                    Label(item.isFavorite ? "Unfavorite" : "Favorite",
                          systemImage: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? Color(hex: 0xF5A524) : DesignTokens.muted)
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    store.delete(item.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            BrandMark(seed: item.brandSeed, size: 58, radius: 13)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.nd(22, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("Login")
                    .font(.nd(11.5, weight: .semibold))
                    .foregroundStyle(DesignTokens.accentInk)
            }
            Spacer()
        }
    }
}
#endif
