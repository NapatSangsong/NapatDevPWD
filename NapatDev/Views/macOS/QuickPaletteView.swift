#if os(macOS)
import SwiftUI
import AppKit

struct QuickPaletteView: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @State private var didCopy = false
    @FocusState private var searchFocused: Bool

    private var results: [VaultItem] {
        let base = store.items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        guard !query.isEmpty else { return Array(base.prefix(10)) }
        let q = query.lowercased()
        return Array(
            base.filter {
                $0.title.lowercased().contains(q) ||
                $0.username.lowercased().contains(q) ||
                $0.website.lowercased().contains(q)
            }.prefix(10)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider().background(DesignTokens.hairline)
            resultsList
        }
        .frame(width: 520, height: 400)
        .background(DesignTokens.cardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(DesignTokens.hairline, lineWidth: 0.5)
        )
        .onAppear { searchFocused = true }
        .onChange(of: query) { _, _ in selectedIndex = 0 }
        .onKeyPress(.downArrow) {
            selectedIndex = min(selectedIndex + 1, results.count - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.return) {
            copySelected()
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.muted)
            TextField("Type to search…", text: $query)
                .textFieldStyle(.plain)
                .font(.nd(16))
                .focused($searchFocused)
                .onSubmit { copySelected() }
            if didCopy {
                Label("Copied", systemImage: "checkmark.circle.fill")
                    .font(.nd(11, weight: .semibold))
                    .foregroundStyle(DesignTokens.good)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var resultsList: some View {
        Group {
            if results.isEmpty {
                empty
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { idx, item in
                                row(item, isSelected: idx == selectedIndex)
                                    .id(idx)
                                    .onTapGesture {
                                        selectedIndex = idx
                                        copySelected()
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onChange(of: selectedIndex) { _, idx in
                        withAnimation(.linear(duration: 0.1)) {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.muted2)
            Text(query.isEmpty ? "Nothing in your vault yet." : "No matches.")
                .font(.nd(12.5))
                .foregroundStyle(DesignTokens.muted)
            Text("↵ to copy · Esc to close")
                .font(.ndMono(10))
                .foregroundStyle(DesignTokens.muted2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ item: VaultItem, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            BrandMark(seed: item.brandSeed, size: 26, radius: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.nd(13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : DesignTokens.ink)
                    .lineLimit(1)
                Text(item.username)
                    .font(.nd(11))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : DesignTokens.muted)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "return")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.white.opacity(0.8) : DesignTokens.muted2)
                .opacity(isSelected ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .top, endPoint: .bottom))
            }
        }
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }

    private func copySelected() {
        guard results.indices.contains(selectedIndex) else { return }
        let item = results[selectedIndex]
        ClipboardManager.copy(item.password)
        didCopy = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            dismiss()
        }
    }
}
#endif
