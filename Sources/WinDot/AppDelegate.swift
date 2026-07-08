import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

/// Cmd+Period, matching Windows' Win+. muscle memory. Note: this is also the
/// conventional Cocoa "Cancel/Stop" shortcut (e.g. Safari's Stop Loading), but as
/// a Carbon global hotkey it takes priority system-wide. Change here if it conflicts
/// with something you use often.
enum HotkeyConfig {
    static let keyCode: UInt32 = UInt32(kVK_ANSI_Period)
    static let modifiers: UInt32 = UInt32(cmdKey)
}

// MARK: - App delegate: hotkey + panel

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var panel: NSPanel!
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var previousApp: NSRunningApplication?
    let model = PickerModel()
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyAppearance()
        setupMainMenu()
        setupStatusItem()
        setupPanel()
        registerHotKey()
        Accessibility.ensureTrusted()

        // If the user dismisses WinDot by clicking back onto the app they hailed it
        // from (instead of Esc / the close button), treat that as "changed their mind"
        // and hide the panel to match.
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(frontmostAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil
        )
    }

    @objc func frontmostAppChanged(_ note: Notification) {
        guard panel.isVisible,
              let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.processIdentifier == previousApp?.processIdentifier
        else { return }
        hidePanel()
    }

    private func applyAppearance() {
        NSApp.appearance = AppSettings.appearanceMode.nsAppearance
    }

    /// Accessory apps get no menu bar by default, which means Cmd+V/C/X/A never route to
    /// the standard paste:/copy:/cut:/selectAll: actions in any text field (search box,
    /// API key field) — only right-click's contextual menu works without this. A minimal
    /// Edit menu is enough to make the keyboard shortcuts work everywhere in the app.
    func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Quit WinDot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            // Plain text reads far less ambiguously in the menu bar than a generic glyph,
            // and doubles as a standing reminder of the hotkey itself.
            button.title = "⌘."
        }

        let menu = NSMenu()
        loginItem.target = self
        menu.addItem(NSMenuItem(title: "Open WinDot (⌘.)", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(defaultTabMenuItem())
        menu.addItem(appearanceMenuItem())
        menu.addItem(.separator())
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Open Config File", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reset Accessibility Permission", action: #selector(resetAccessibility), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "☕ Buy Me a Coffee", action: #selector(openBuyMeACoffee), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Uninstall WinDot…", action: #selector(uninstall), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WinDot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        statusItem.menu = menu

        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func defaultTabMenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        for tab in PickerTab.allCases {
            let item = NSMenuItem(title: tab.title, action: #selector(setDefaultTab(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tab.rawValue
            item.state = AppSettings.defaultTab == tab ? .on : .off
            submenu.addItem(item)
        }
        let parent = NSMenuItem(title: "Default Tab", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        return parent
    }

    @objc func setDefaultTab(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let tab = PickerTab(rawValue: raw) else { return }
        AppSettings.defaultTab = tab
        sender.menu?.items.forEach { $0.state = ($0 == sender) ? .on : .off }
    }

    private func appearanceMenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        for mode in AppearanceMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(setAppearanceMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = AppSettings.appearanceMode == mode ? .on : .off
            submenu.addItem(item)
        }
        let parent = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        return parent
    }

    @objc func setAppearanceMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = AppearanceMode(rawValue: raw) else { return }
        AppSettings.appearanceMode = mode
        applyAppearance()
        sender.menu?.items.forEach { $0.state = ($0 == sender) ? .on : .off }
    }

    @objc func toggleLoginItem() {
        do {
            if loginItem.state == .on {
                try SMAppService.mainApp.unregister()
                loginItem.state = .off
            } else {
                try SMAppService.mainApp.register()
                loginItem.state = .on
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't update Login Item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    @objc func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Ad-hoc-signed rebuilds can leave a stale TCC grant that shows as checked but
    /// silently fails. `tccutil reset` clears WinDot's entry entirely so the next
    /// ensureTrusted() call re-prompts cleanly, instead of manual remove-and-re-add.
    @objc func resetAccessibility() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task.arguments = ["reset", "Accessibility", "com.jackharvest.windot"]
        try? task.run()
        task.waitUntilExit()
        Accessibility.ensureTrusted()
    }

    @objc func openBuyMeACoffee() {
        if let url = URL(string: "https://buymeacoffee.com/jackharvest") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openConfig() {
        let dir = APIKeyStore.configURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: APIKeyStore.configURL.path) {
            let template = "{\n  \"apiKey\": \"YOUR_GIPHY_KEY_HERE\"\n}\n"
            try? template.write(to: APIKeyStore.configURL, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(APIKeyStore.configURL)
    }

    @objc func uninstall() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Uninstall WinDot?"
        alert.informativeText = "This removes WinDot from Login Items, clears its saved config, and moves WinDot.app to the Trash. You can restore it from the Trash if you change your mind."
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        try? SMAppService.mainApp.unregister()
        try? FileManager.default.removeItem(at: APIKeyStore.configURL)

        let bundleURL = Bundle.main.bundleURL
        try? FileManager.default.trashItem(at: bundleURL, resultingItemURL: nil)

        NSApplication.shared.terminate(nil)
    }

    func setupPanel() {
        let view = GifPickerView(
            model: model,
            onPickGif: { [weak self] gif in ClipboardWriter.pasteGif(gif, restoreFocusTo: self?.previousApp) },
            onPickEmoji: { [weak self] emoji in ClipboardWriter.pasteText(emoji, restoreFocusTo: self?.previousApp) },
            onClose: { [weak self] in self?.hidePanel() }
        )
        let hosting = NSHostingView(rootView: view)
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.contentView = hosting
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
    }

    @objc func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            previousApp = NSWorkspace.shared.frontmostApplication
            showPanel()
        }
    }

    func showPanel() {
        model.tab = AppSettings.defaultTab
        model.resetForFreshOpen()
        let margin: CGFloat = 12
        if let pid = previousApp?.processIdentifier,
           let windowFrame = WindowLocator.frontmostWindowFrame(pid: pid),
           let screen = NSScreen.screens.first(where: { NSPointInRect(windowFrame.origin, $0.frame) }) ?? NSScreen.main {
            // Align WinDot's bottom-right corner to the hailing app's window's bottom-right corner.
            var x = windowFrame.maxX - panel.frame.width - margin
            var y = windowFrame.minY + margin
            let visible = screen.visibleFrame
            x = min(max(x, visible.minX), visible.maxX - panel.frame.width)
            y = min(max(y, visible.minY), visible.maxY - panel.frame.height)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main {
            // Fallback: no window frame available, anchor near the mouse instead of dead-center.
            let mouse = NSEvent.mouseLocation
            let visible = screen.visibleFrame
            var x = mouse.x - panel.frame.width / 2
            var y = mouse.y - panel.frame.height - 16
            x = min(max(x, visible.minX), visible.maxX - panel.frame.width)
            y = min(max(y, visible.minY), visible.maxY - panel.frame.height)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        model.isPanelVisible = true
    }

    func hidePanel() {
        panel.orderOut(nil)
        model.isPanelVisible = false
        previousApp?.activate()
    }

    /// Routes the native titlebar close button through hidePanel() so it gets the same
    /// refocus-previous-app behavior as Esc and re-pressing ⌘. — without this, clicking
    /// the X closed the window via AppKit's default path and silently skipped refocusing.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hidePanel()
        return false
    }

    func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4746_4B31), id: 1) // 'GFK1'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { delegate.togglePanel() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        RegisterEventHotKey(
            HotkeyConfig.keyCode,
            HotkeyConfig.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
