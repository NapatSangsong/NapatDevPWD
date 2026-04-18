import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Copies a string to the pasteboard and schedules a clear after `timeout`.
/// If the user copies something else in the meantime, the clear is skipped
/// (we check the pasteboard's change count before wiping).
enum ClipboardManager {
    static let defaultTimeout: TimeInterval = 30

    @MainActor
    static func copy(_ string: String, clearAfter timeout: TimeInterval = defaultTimeout) {
        let snapshotCount = write(string)
        Task {
            try? await Task.sleep(for: .seconds(timeout))
            clearIfUnchanged(since: snapshotCount)
        }
    }

    // MARK: - Platform backends

    @discardableResult
    private static func write(_ string: String) -> Int {
        #if canImport(UIKit)
        let pb = UIPasteboard.general
        pb.string = string
        return pb.changeCount
        #elseif canImport(AppKit)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
        return pb.changeCount
        #else
        return 0
        #endif
    }

    private static func clearIfUnchanged(since snapshot: Int) {
        #if canImport(UIKit)
        let pb = UIPasteboard.general
        guard pb.changeCount == snapshot else { return }
        pb.items = []
        #elseif canImport(AppKit)
        let pb = NSPasteboard.general
        guard pb.changeCount == snapshot else { return }
        pb.clearContents()
        #endif
    }
}
