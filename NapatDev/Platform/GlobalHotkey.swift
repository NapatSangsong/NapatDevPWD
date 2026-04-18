#if os(macOS)
import Foundation
import Carbon.HIToolbox
import AppKit

/// Registers a system-wide hotkey via Carbon's `RegisterEventHotKey` and
/// invokes a callback when pressed. Works without the accessibility permission
/// (unlike `NSEvent` global monitors).
///
/// Default combination: **⌃⌥⌘P** — Control + Option + Command + P.
final class GlobalHotkey {
    typealias Handler = @MainActor () -> Void

    static let shared = GlobalHotkey()

    private var hotKeyRef: EventHotKeyRef?
    private var handler: Handler?
    private var eventHandler: EventHandlerRef?

    private init() {}

    /// Register a hotkey. Safe to call multiple times — previous registration
    /// is replaced.
    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_P),
        modifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey),
        handler: @escaping Handler
    ) {
        unregister()
        self.handler = handler

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E415054), id: 1) // 'NAPT'
        var ref: EventHotKeyRef?
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard regStatus == noErr, let ref else { return }
        self.hotKeyRef = ref

        if eventHandler == nil {
            var spec = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, event, userData -> OSStatus in
                    guard let userData, let event else { return noErr }
                    let this = Unmanaged<GlobalHotkey>.fromOpaque(userData).takeUnretainedValue()
                    var received = EventHotKeyID()
                    GetEventParameter(
                        event,
                        OSType(kEventParamDirectObject),
                        OSType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &received
                    )
                    if received.id == 1 {
                        DispatchQueue.main.async {
                            MainActor.assumeIsolated { this.handler?() }
                        }
                    }
                    return noErr
                },
                1,
                &spec,
                selfPtr,
                &eventHandler
            )
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
#endif
