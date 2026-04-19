#if os(macOS)
import SwiftUI

struct VaultSidebar: View {
    @Environment(VaultStore.self) private var store
    @Environment(AppLockModel.self) private var lock
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AssistantSettings.self) private var assistantSettings
    @Environment(SyncModel.self) private var sync
    @State private var biometricError: String?
    @State private var showingSyncSignIn = false

    var body: some View {
        @Bindable var themeBinding = themeManager
        @Bindable var assistantBinding = assistantSettings
        return List {
            Section {
                HStack(spacing: 8) {
                    appIconTile
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Napat Dev")
                            .font(.nd(13, weight: .bold))
                            .foregroundStyle(DesignTokens.ink)
                        Text(store.vaults.first?.name ?? "Personal")
                            .font(.nd(11))
                            .foregroundStyle(DesignTokens.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }
            Section {
                sidebarRow(icon: "person", label: "Profile")
                sidebarRow(icon: "lock.shield", label: "Personal")
                sidebarRow(icon: "star", label: "Favorites")
            }
            Section("Appearance") {
                Picker("Theme", selection: $themeBinding.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }
            Section("Auto-lock") {
                Picker("Lock after", selection: Binding(
                    get: { lock.autoLockSeconds },
                    set: { lock.autoLockSeconds = $0 }
                )) {
                    Text("Immediately").tag(0)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                }
                .pickerStyle(.menu)
                .listRowBackground(Color.clear)
            }
            Section("Assistant") {
                Picker("Model", selection: $assistantBinding.model) {
                    ForEach(AssistantModel.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .listRowBackground(Color.clear)
            }
            if lock.biometricsAvailable {
                Section("Security") {
                    Toggle(isOn: Binding(
                        get: { lock.biometricsEnabled },
                        set: { toggleBiometrics($0) }
                    )) {
                        Label("Unlock with \(lock.biometricKind.label)",
                              systemImage: lock.biometricKind.systemImage)
                            .font(.nd(12.5))
                    }
                    .listRowBackground(Color.clear)
                }
            }
            if sync.isConfigured {
                Section("Sync (Supabase)") {
                    syncStatusRow
                }
            }
            Section("System") {
                Toggle(isOn: Binding(
                    get: { LoginItem.isEnabled },
                    set: { toggleLoginItem($0) }
                )) {
                    Label("Launch at login", systemImage: "power")
                        .font(.nd(12.5))
                }
                .listRowBackground(Color.clear)
                HStack(spacing: 6) {
                    Image(systemName: "command").font(.system(size: 11))
                    Text("Global hotkey: ⌃⌥⌘P")
                        .font(.nd(11))
                }
                .foregroundStyle(DesignTokens.muted)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.sidebar)
        .background(DesignTokens.surface2)
        .sheet(isPresented: $showingSyncSignIn) {
            SyncSignInSheet().environment(sync)
        }
        .alert("Couldn't enable biometrics", isPresented: Binding(
            get: { biometricError != nil },
            set: { if !$0 { biometricError = nil } }
        )) {
            Button("OK", role: .cancel) { biometricError = nil }
        } message: {
            Text(biometricError ?? "")
        }
    }

    private func toggleBiometrics(_ enabled: Bool) {
        if enabled {
            do { try lock.enableBiometrics() }
            catch { biometricError = error.localizedDescription }
        } else {
            lock.disableBiometrics()
        }
    }

    private func toggleLoginItem(_ enabled: Bool) {
        try? LoginItem.setEnabled(enabled)
    }

    @ViewBuilder
    private var syncStatusRow: some View {
        switch sync.status {
        case .disabled:
            EmptyView()
        case .signedOut:
            Button {
                showingSyncSignIn = true
            } label: {
                Label("Sign in to sync", systemImage: "icloud")
                    .font(.nd(12.5, weight: .medium))
            }
            .listRowBackground(Color.clear)
        case .signedIn(let email):
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundStyle(DesignTokens.good)
                    Text("Synced").font(.nd(12, weight: .semibold))
                    Spacer()
                    Button("Sign out") { sync.signOut() }
                        .font(.nd(11))
                        .buttonStyle(.plain)
                        .foregroundStyle(DesignTokens.muted)
                }
                Text(email)
                    .font(.nd(11))
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
            }
            .listRowBackground(Color.clear)
        case .syncing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Syncing…").font(.nd(12)).foregroundStyle(DesignTokens.muted)
            }
            .listRowBackground(Color.clear)
        case .error(let msg):
            VStack(alignment: .leading, spacing: 4) {
                Label("Sync error", systemImage: "exclamationmark.icloud.fill")
                    .font(.nd(12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xE11D48))
                Text(msg).font(.nd(10.5)).foregroundStyle(DesignTokens.muted).lineLimit(2)
                Button("Retry sign in") { showingSyncSignIn = true }
                    .font(.nd(11))
                    .buttonStyle(.plain)
            }
            .listRowBackground(Color.clear)
        }
    }

    private func sidebarRow(icon: String, label: String) -> some View {
        Label(label, systemImage: icon)
            .font(.nd(12.5, weight: .medium))
            .foregroundStyle(DesignTokens.ink2)
    }

    private var appIconTile: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x5B7CFA), Color(hex: 0x8AA1FF)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: "house.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
            )
    }
}
#endif
