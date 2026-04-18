#if os(macOS)
import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @Environment(VaultStore.self) private var store
    @Environment(AppLockModel.self) private var lock
    @State private var query: String = ""
    @State private var copiedID: VaultItem.ID?

    private var results: [VaultItem] {
        let base = store.items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        guard !query.isEmpty else {
            return Array(base.filter(\.isFavorite).prefix(8))
        }
        let q = query.lowercased()
        return Array(
            base.filter {
                $0.title.lowercased().contains(q) ||
                $0.username.lowercased().contains(q) ||
                $0.website.lowercased().contains(q)
            }.prefix(8)
        )
    }

    var body: some View {
        Group {
            if lock.state != .unlocked {
                lockedState
            } else {
                unlockedState
            }
        }
        .frame(width: 320)
        .background(DesignTokens.cardSolid)
    }

    private var lockedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.accent)
            Text("Vault is locked")
                .font(.nd(13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Button("Open Napat Dev") { openMainWindow() }
                .controlSize(.small)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var unlockedState: some View {
        VStack(spacing: 0) {
            header
            Divider().background(DesignTokens.hairline)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .font(.nd(12.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Divider().background(DesignTokens.hairline)
            content
            Divider().background(DesignTokens.hairline)
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x5B7CFA), Color(hex: 0x8AA1FF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "key.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text("Napat Dev")
                .font(.nd(13, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if results.isEmpty {
                    Text(query.isEmpty ? "Star items to pin them here." : "No matches.")
                        .font(.nd(11.5))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(results) { item in
                        row(for: item)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 280)
    }

    private func row(for item: VaultItem) -> some View {
        Button {
            ClipboardManager.copy(item.password)
            copiedID = item.id
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                if copiedID == item.id { copiedID = nil }
            }
        } label: {
            HStack(spacing: 8) {
                BrandMark(seed: item.brandSeed, size: 22, radius: 5)
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .font(.nd(12.5, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                    if !item.username.isEmpty {
                        Text(item.username)
                            .font(.nd(10.5))
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: copiedID == item.id ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(copiedID == item.id ? DesignTokens.good : DesignTokens.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(copiedID == item.id ? DesignTokens.accentSoft : Color.clear)
        )
        .padding(.horizontal, 6)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button { openMainWindow() } label: {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            .controlSize(.small)
            Spacer()
            Button { lock.lock() } label: {
                Label("Lock", systemImage: "lock")
            }
            .controlSize(.small)
            Button(role: .destructive) { NSApp.terminate(nil) } label: {
                Label("Quit", systemImage: "power")
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
#endif
