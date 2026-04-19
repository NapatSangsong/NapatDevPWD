import SwiftUI
import AppKit

@main
struct NapatDevApp: App {
    @State private var lock = AppLockModel()
    @State private var store = VaultStore()
    @State private var theme = ThemeManager()
    @State private var assistantSettings = AssistantSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        mainWindow
        menuBar
    }

    @SceneBuilder
    private var mainWindow: some Scene {
        WindowGroup {
            RootGate()
                .environment(lock)
                .environment(store)
                .environment(theme)
                .environment(assistantSettings)
                .preferredColorScheme(theme.theme.colorScheme)
                .onChange(of: lock.state) { _, newState in
                    Task { @MainActor in
                        switch newState {
                        case .unlocked:
                            if let key = lock.key { await store.bind(key: key) }
                        case .locked, .needsSetup:
                            store.unbind()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        lock.scheduleAutoLock()
                    case .active, .inactive:
                        lock.cancelScheduledLock()
                    @unknown default:
                        break
                    }
                }
                .onAppear { registerGlobalHotkey() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1040, height: 680)
        .commands { appCommands }
    }

    @CommandsBuilder
    private var appCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Item") { AppCommand.newItem.post() }
                .keyboardShortcut("n", modifiers: .command)
        }
        CommandGroup(after: .sidebar) {
            Button("Focus Search") { AppCommand.focusSearch.post() }
                .keyboardShortcut("f", modifiers: .command)
            Button("Quick Open…") { AppCommand.openQuickPalette.post() }
                .keyboardShortcut("k", modifiers: .command)
            Divider()
            Button("Lock Vault") { AppCommand.lockVault.post() }
                .keyboardShortcut("l", modifiers: .command)
        }
        CommandGroup(after: .importExport) {
            Button("Export Encrypted Backup…") { AppCommand.backupVault.post() }
            Button("Restore From Backup…") { AppCommand.restoreVault.post() }
        }
    }

    @SceneBuilder
    private var menuBar: some Scene {
        MenuBarExtra("Napat Dev", systemImage: "key.fill") {
            MenuBarPopoverView()
                .environment(lock)
                .environment(store)
                .environment(theme)
                .environment(assistantSettings)
                .preferredColorScheme(theme.theme.colorScheme)
        }
        .menuBarExtraStyle(.window)
    }

    private func registerGlobalHotkey() {
        GlobalHotkey.shared.register { [self] in
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

private struct RootGate: View {
    @Environment(AppLockModel.self) private var lock

    var body: some View {
        switch lock.state {
        case .needsSetup:
            OnboardingView()
        case .locked:
            UnlockView()
        case .unlocked:
            DesktopRootView()
        }
    }
}
