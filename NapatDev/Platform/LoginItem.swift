#if os(macOS)
import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` for a one-tap "Launch at login" toggle.
/// Requires macOS 13+ (our min is 14).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
#endif
