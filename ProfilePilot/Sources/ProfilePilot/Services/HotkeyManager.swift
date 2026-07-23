import Foundation
import Carbon.HIToolbox
import AppKit

/// Registers Carbon global hotkeys for each workspace that has one.
/// Carbon (`RegisterEventHotKey`) is used instead of `NSEvent.addGlobalMonitor…`
/// because only Carbon lets us *swallow* the key press.
final class HotkeyManager {

    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var nextID: UInt32 = 1

    init() { installHandler() }
    deinit { unbindAll() }

    // MARK: - Public API

    func rebindAll(from workspaces: [Workspace]) {
        unbindAll()
        for ws in workspaces {
            guard let spec = ws.hotkey else { continue }
            bind(spec: spec) { [weak self] in
                guard self != nil else { return }
                Task { @MainActor in
                    AppState.shared.launch(ws)
                }
            }
        }
    }

    func bind(spec: HotkeySpec, action: @escaping () -> Void) {
        var hotKeyRef: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x50504C54 /* 'PPLT' */), id: nextID)
        let status = RegisterEventHotKey(spec.keyCode,
                                         spec.modifiers,
                                         id,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        guard status == noErr, let ref = hotKeyRef else { return }
        refs.append(ref)
        handlers[id.id] = action
        nextID &+= 1
    }

    func unbindAll() {
        for ref in refs { UnregisterEventHotKey(ref) }
        refs.removeAll()
        handlers.removeAll()
    }

    // MARK: - Internal

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, ctx) -> OSStatus in
                guard let event, let ctx else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(ctx).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event,
                                  EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID),
                                  nil,
                                  MemoryLayout<EventHotKeyID>.size,
                                  nil,
                                  &hotKeyID)
                DispatchQueue.main.async {
                    manager.handlers[hotKeyID.id]?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }
}
