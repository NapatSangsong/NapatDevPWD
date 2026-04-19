#if os(macOS)
import SwiftUI

struct ItemListView: View {
    let items: [VaultItem]
    @Binding var query: String
    @Binding var selectedID: VaultItem.ID?
    var onNew: () -> Void
    @Environment(TagFilterModel.self) private var tagFilter
    @FocusState private var searchFocused: Bool

    private var filtered: [VaultItem] {
        let sorted = items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let tagScoped = tagFilter.apply(to: sorted)
        guard !query.isEmpty else { return tagScoped }
        // `#foo` searches tag only; otherwise title/username/website/tag all match.
        if query.hasPrefix("#") {
            let q = query.dropFirst().lowercased()
            return tagScoped.filter { item in
                item.tags.contains(where: { $0.lowercased().contains(q) })
            }
        }
        let q = query.lowercased()
        return tagScoped.filter {
            $0.title.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            $0.website.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    private var grouped: [(String, [VaultItem])] {
        let groups = Dictionary(grouping: filtered, by: \.groupLetter)
        return groups.keys.sorted().map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(DesignTokens.hairline)
            tagChipsBar
            content
        }
        .background(DesignTokens.surface2)
        .onAppCommand(.focusSearch) { searchFocused = true }
    }

    @ViewBuilder
    private var tagChipsBar: some View {
        let tags = TagFilterModel.allTags(from: items)
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    TagChip(text: "All", selected: tagFilter.selected == nil) {
                        tagFilter.selected = nil
                    }
                    ForEach(tags, id: \.tag) { entry in
                        TagChip(
                            text: "\(entry.tag) · \(entry.count)",
                            selected: tagFilter.selected == entry.tag
                        ) {
                            tagFilter.toggle(entry.tag)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .background(DesignTokens.cardSolid.opacity(0.4))
            Divider().background(DesignTokens.hairline)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)
            Text("All Items")
                .font(.nd(12.5, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Spacer()
            Button(action: onNew) {
                Label("New Item", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(DesignTokens.muted)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(DesignTokens.cardSolid.opacity(0.7))
        .overlay(searchField, alignment: .bottom)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .font(.nd(12.5))
                .focused($searchFocused)
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(DesignTokens.surface3, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .frame(height: 36)
        .offset(y: 30)
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray").font(.system(size: 22)).foregroundStyle(DesignTokens.muted2)
                Text(query.isEmpty ? "No items yet. Tap + to add one." : "No items match \"\(query)\"")
                    .font(.nd(12)).foregroundStyle(DesignTokens.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selectedID) {
                ForEach(grouped, id: \.0) { letter, list in
                    Section {
                        ForEach(list) { item in
                            ItemRow(item: item, selected: selectedID == item.id)
                                .tag(item.id as VaultItem.ID?)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text(letter)
                            .font(.nd(10.5, weight: .bold))
                            .tracking(0.3)
                            .foregroundStyle(DesignTokens.muted2)
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
        }
    }
}
#endif
