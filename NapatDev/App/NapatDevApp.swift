import SwiftUI
import AppKit

@main
struct NapatDevApp: App {
    @State private var lock = AppLockModel()
    @State private var store = VaultStore()
    @State private var theme = ThemeManager()
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
                    if phase == .background { lock.lock() }
                }
                .onAppear { registerGlobalHotkey() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1040, height: 680)
    }

    @SceneBuilder
    private var menuBar: some Scene {
        MenuBarExtra("Napat Dev", systemImage: "key.fill") {
            MenuBarPopoverView()
                .environment(lock)
                .environment(store)
                .environment(theme)
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
