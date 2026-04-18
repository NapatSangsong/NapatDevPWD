#if os(macOS)
import SwiftUI

struct VaultSidebar: View {
    @Environment(VaultStore.self) private var store
    @Environment(AppLockModel.self) private var lock
    @State private var themeManager = ThemeManager()
    @State private var biometricError: String?

    var body: some View {
        List {
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
                Picker("Theme", selection: $themeManager.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
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
