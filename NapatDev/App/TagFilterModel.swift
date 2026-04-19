import Foundation
import Observation

@MainActor
@Observable
final class TagFilterModel {
    /// Currently-selected tag, or nil for "All items".
    var selected: String?

    func toggle(_ tag: String) {
        if selected == tag { selected = nil }
        else { selected = tag }
    }

    /// Filter a sequence of items. Nil tag = passthrough.
    func apply(to items: [VaultItem]) -> [VaultItem] {
        guard let tag = selected else { return items }
        let lower = tag.lowercased()
        return items.filter { $0.tags.contains(where: { $0.lowercased() == lower }) }
    }

    /// Collect all tags across the vault sorted by frequency then alphabetical.
    static func allTags(from items: [VaultItem]) -> [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            for t in item.tags {
                counts[t, default: 0] += 1
            }
        }
        return counts
            .map { ($0.key, $0.value) }
            .sorted { a, b in
                a.1 != b.1 ? a.1 > b.1 : a.0.localizedCaseInsensitiveCompare(b.0) == .orderedAscending
            }
    }
}
