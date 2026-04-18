#if os(macOS)
import SwiftUI

struct DesktopRootView: View {
    @Environment(VaultStore.self) private var store
    @Environment(AppLockModel.self) private var lock
    @State private var selectedID: VaultItem.ID?
    @State private var query: String = ""
    @State private var showingEditor = false
    @State private var editingItem: VaultItem?
    @State private var showingAssistant = false

    var body: some View {
        NavigationSplitView {
            VaultSidebar()
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 240)
        } content: {
            ItemListView(
                items: store.items,
                query: $query,
                selectedID: $selectedID,
                onNew: {
                    editingItem = nil
                    showingEditor = true
                }
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        } detail: {
            if let id = selectedID, let item = store.items.first(where: { $0.id == id }) {
                ItemDetailView(item: item, onEdit: {
                    editingItem = item
                    showingEditor = true
                })
            } else {
                EmptyDetail()
            }
        }
        .navigationTitle("Napat Dev")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEditor) {
            ItemEditorView(item: editingItem)
                .frame(minWidth: 460, minHeight: 540)
        }
        .sheet(isPresented: $showingAssistant) {
            ChatView()
                .frame(minWidth: 520, minHeight: 620)
        }
        .onAppear {
            if selectedID == nil, let first = store.items.sorted(by: { $0.title < $1.title }).first {
                selectedID = first.id
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                editingItem = nil
                showingEditor = true
            } label: {
                Label("New Item", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .automatic) {
            Button {
                showingAssistant = true
            } label: {
                Label("Assistant", systemImage: "sparkles")
            }
        }
        ToolbarItem(placement: .automatic) {
            Button {
                lock.lock()
            } label: {
                Label("Lock", systemImage: "lock")
            }
        }
    }
}

private struct EmptyDetail: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 38))
                .foregroundStyle(DesignTokens.accent)
                .padding(24)
                .background(DesignTokens.accentSoft, in: Circle())
            Text("Select an item")
                .font(.nd(15, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text("Choose a login from the list, or create a new one.")
                .font(.nd(12.5))
                .foregroundStyle(DesignTokens.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.cardSolid)
    }
}
#endif
