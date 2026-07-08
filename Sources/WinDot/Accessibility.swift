import AppKit
import ApplicationServices

// MARK: - Accessibility

enum Accessibility {
    static func ensureTrusted() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}

// MARK: - Frontmost window location (via Accessibility)

enum WindowLocator {
    /// Screen frame (Cocoa coords, bottom-left origin) of the given app's focused/main
    /// window. Window-level AX attributes are exposed by virtually every app, including
    /// Electron/Chromium ones that otherwise skip building a full accessibility tree
    /// (unlike caret/text-position attributes, which those apps only expose when a
    /// screen reader is actively running).
    static func frontmostWindowFrame(pid: pid_t) -> CGRect? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowRef: AnyObject?
        var result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef)
        if result != .success || windowRef == nil {
            result = AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &windowRef)
        }
        guard result == .success, let windowRef else { return nil }
        let window = windowRef as! AXUIElement

        var posRef: AnyObject?
        var sizeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef else { return nil }

        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)

        guard let primary = NSScreen.screens.first else { return nil }
        let flippedY = primary.frame.height - point.y - size.height
        return CGRect(x: point.x, y: flippedY, width: size.width, height: size.height)
    }
}
