import Foundation
import SwiftUI

/// App-wide commands bound to keyboard shortcuts. Views that want to react
/// observe the corresponding `Notification.Name` — this keeps command wiring
/// decoupled from concrete views (works for both the main window and the
/// menu-bar popover).
enum AppCommand: String, CaseIterable {
    case newItem
    case focusSearch
    case lockVault
    case openQuickPalette
    case backupVault
    case restoreVault

    var notificationName: Notification.Name {
        Notification.Name("NapatDev.Command.\(rawValue)")
    }

    func post() {
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
}

extension View {
    /// Runs `action` whenever the given command fires.
    func onAppCommand(_ command: AppCommand, perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: command.notificationName)) { _ in
            action()
        }
    }
}
