#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DesktopRootView: View {
    @Environment(VaultStore.self) private var store
    @Environment(AppLockModel.self) private var lock
    @State private var selectedID: VaultItem.ID?
    @State private var query: String = ""
    @State private var showingEditor = false
    @State private var editingItem: VaultItem?
    @State private var showingAssistant = false
    @State private var showingPalette = false
    @State private var banner: (text: String, isError: Bool)?
    @State private var pendingRestoreData: Data?
    @State private var restorePassword: String = ""
    @State private var restoreError: String?

    var body: some View {
        NavigationSplitView {
            VaultSidebar()
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 240)
        } content: {
            ItemListView(
                items: store.items,
                query: $query,
                selectedID: $selectedID,
                onNew: startNewItem
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
        .sheet(isPresented: $showingPalette) {
            QuickPaletteView()
        }
        .sheet(isPresented: Binding(
            get: { pendingRestoreData != nil },
            set: { if !$0 { cancelRestorePrompt() } }
        )) {
            restorePasswordSheet
        }
        .overlay(alignment: .top) { bannerView }
        .onAppAndCommandWiring(
            onNew: startNewItem,
            onLock: { lock.lock() },
            onPalette: { showingPalette = true },
            onBackup: runBackup,
            onRestore: runRestorePicker
        )
        .onAppear {
            if selectedID == nil, let first = store.items.sorted(by: { $0.title < $1.title }).first {
                selectedID = first.id
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: startNewItem) {
                Label("New Item", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        ToolbarItem(placement: .automatic) {
            Button { showingPalette = true } label: {
                Label("Quick Open", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("k", modifiers: .command)
        }
        ToolbarItem(placement: .automatic) {
            Button { showingAssistant = true } label: {
                Label("Assistant", systemImage: "sparkles")
            }
        }
        ToolbarItem(placement: .automatic) {
            Button { lock.lock() } label: {
                Label("Lock", systemImage: "lock")
            }
            .keyboardShortcut("l", modifiers: .command)
        }
    }

    // MARK: - Actions

    private func startNewItem() {
        editingItem = nil
        showingEditor = true
    }

    private func runBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "napatvaultbackup") ?? .data]
        panel.nameFieldStringValue = "napat-dev-\(Self.filenameDateFormatter.string(from: .now)).napatvaultbackup"
        panel.canCreateDirectories = true
        panel.title = "Export encrypted backup"
        guard panel.runModal() == .OK, let url = panel.url, let key = lock.key else { return }

        do {
            let data = try VaultBackupIO.exportBackup(using: store.currentFile, key: key)
            try data.write(to: url, options: .atomic)
            show(banner: "Backup saved to \(url.lastPathComponent)", isError: false)
        } catch {
            show(banner: "Backup failed: \(error.localizedDescription)", isError: true)
        }
    }

    private func runRestorePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "napatvaultbackup") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Restore from encrypted backup"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            pendingRestoreData = data
            restorePassword = ""
            restoreError = nil
        } catch {
            show(banner: "Couldn't read backup: \(error.localizedDescription)", isError: true)
        }
    }

    private func confirmRestore() {
        guard let data = pendingRestoreData else { return }
        do {
            let (file, key, salt, verifier) = try VaultBackupIO.importBackup(data, password: restorePassword)
            lock.applyRestoredCredentials(key: key, salt: salt, verifier: verifier)
            store.replaceAll(with: file)
            pendingRestoreData = nil
            restorePassword = ""
            show(banner: "Vault restored — \(file.items.count) items loaded.", isError: false)
        } catch {
            restoreError = error.localizedDescription
        }
    }

    private func cancelRestorePrompt() {
        pendingRestoreData = nil
        restorePassword = ""
        restoreError = nil
    }

    // MARK: - Restore password sheet

    private var restorePasswordSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Restore encrypted backup")
                .font(.nd(16, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
            Text("Enter the master password that was active when this backup was made. Your current vault will be replaced.")
                .font(.nd(12))
                .foregroundStyle(DesignTokens.muted)
            SecureField("Master password", text: $restorePassword)
                .textFieldStyle(.roundedBorder)
                .onSubmit(confirmRestore)
            if let restoreError {
                Text(restoreError)
                    .font(.nd(11.5))
                    .foregroundStyle(Color(hex: 0xE11D48))
            }
            HStack {
                Spacer()
                Button("Cancel", action: cancelRestorePrompt)
                Button("Restore", action: confirmRestore)
                    .keyboardShortcut(.defaultAction)
                    .disabled(restorePassword.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    // MARK: - Banner

    @ViewBuilder
    private var bannerView: some View {
        if let banner {
            Text(banner.text)
                .font(.nd(12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background((banner.isError ? Color(hex: 0xE11D48) : DesignTokens.good),
                            in: Capsule())
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func show(banner text: String, isError: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            banner = (text, isError)
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) { banner = nil }
            }
        }
    }

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f
    }()
}

// MARK: - Command wiring modifier

private struct AppCommandsWiring: ViewModifier {
    var onNew: () -> Void
    var onLock: () -> Void
    var onPalette: () -> Void
    var onBackup: () -> Void
    var onRestore: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppCommand(.newItem, perform: onNew)
            .onAppCommand(.lockVault, perform: onLock)
            .onAppCommand(.openQuickPalette, perform: onPalette)
            .onAppCommand(.backupVault, perform: onBackup)
            .onAppCommand(.restoreVault, perform: onRestore)
    }
}

private extension View {
    func onAppAndCommandWiring(
        onNew: @escaping () -> Void,
        onLock: @escaping () -> Void,
        onPalette: @escaping () -> Void,
        onBackup: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> some View {
        modifier(AppCommandsWiring(
            onNew: onNew,
            onLock: onLock,
            onPalette: onPalette,
            onBackup: onBackup,
            onRestore: onRestore
        ))
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
