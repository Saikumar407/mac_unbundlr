import Foundation
import AppKit
import ApplicationServices

/// Reads and restores window frames across displays via the Accessibility API.
/// Requires the user to grant Accessibility permission in
/// *System Settings → Privacy & Security → Accessibility*.
final class WindowLayoutManager {

    // MARK: - Permission

    var isTrusted: Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    /// Requests the permission prompt if the process is not already trusted.
    @discardableResult
    func requestTrust() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    // MARK: - Capture

    func captureCurrentLayout(name: String) -> WindowLayout {
        var entries: [WindowLayout.Entry] = []
        let displays = NSScreen.screens
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            guard let bundleID = app.bundleIdentifier else { continue }
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            guard err == .success,
                  let windows = windowsRef as? [AXUIElement] else { continue }

            for window in windows {
                let frame = frameFor(window: window)
                let title = titleFor(window: window)
                let displayIndex = displays.firstIndex { $0.frame.intersects(frame) } ?? 0
                entries.append(.init(appBundleID: bundleID,
                                     windowTitle: title,
                                     frame: frame,
                                     displayIndex: displayIndex))
            }
        }
        return WindowLayout(name: name, entries: entries)
    }

    // MARK: - Restore

    func restore(layout: WindowLayout) {
        for entry in layout.entries {
            guard let app = NSRunningApplication.runningApplications(
                    withBundleIdentifier: entry.appBundleID).first else { continue }
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp,
                                                kAXWindowsAttribute as CFString,
                                                &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else { continue }
            // Match by window title if we captured one; otherwise pick the first window.
            let target: AXUIElement? = {
                if let title = entry.windowTitle {
                    return windows.first { titleFor(window: $0) == title } ?? windows.first
                } else {
                    return windows.first
                }
            }()
            if let win = target {
                setFrame(entry.frame, for: win)
            }
        }
    }

    // MARK: - Helpers

    private func frameFor(window: AXUIElement) -> CGRect {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var position = CGPoint.zero
        var size = CGSize.zero
        if let posRef {
            AXValueGetValue(posRef as! AXValue, .cgPoint, &position)
        }
        if let sizeRef {
            AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        }
        return CGRect(origin: position, size: size)
    }

    private func titleFor(window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        return titleRef as? String
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) {
        var pos = frame.origin
        var size = frame.size
        if let posValue = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}
