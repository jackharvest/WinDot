import AppKit

// MARK: - Clipboard

enum ClipboardWriter {
    static func pasteText(_ text: String, restoreFocusTo previousApp: NSRunningApplication?) {
        EmojiUsageStore.record(text)
        performPaste(restoreFocusTo: previousApp) { pb in
            pb.setString(text, forType: .string)
        }
    }

    static func pasteGif(_ gif: GifResult, restoreFocusTo previousApp: NSRunningApplication?) {
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: gif.fullURL) else { return }
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("gif")
            try? data.write(to: tmpURL)
            RecentGifsStore.record(gif.asRecent)
            await MainActor.run {
                performPaste(restoreFocusTo: previousApp) { pb in
                    // A single NSPasteboardItem carrying both representations. Mixing the
                    // old declareTypes/setData API with writeObjects (or splitting the data
                    // across multiple items/calls) is documented by Apple as undefined
                    // behavior — that combination was silently dropping the GIF for some
                    // receiving apps.
                    let item = NSPasteboardItem()
                    item.setData(data, forType: NSPasteboard.PasteboardType("public.gif"))
                    item.setData(data, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
                    item.setString(tmpURL.absoluteString, forType: .fileURL)
                    pb.writeObjects([item])
                }
            }
        }
    }

    /// Snapshots whatever's currently on the clipboard, writes the pick, re-focuses the
    /// app the user hailed WinDot from, synthesizes Cmd+V, then restores the original
    /// clipboard contents shortly after — so we never clobber the user's existing clipboard.
    private static func performPaste(restoreFocusTo previousApp: NSRunningApplication?, _ write: (NSPasteboard) -> Void) {
        let pb = NSPasteboard.general
        let snapshot = (pb.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                guard let data = item.data(forType: type) else { return nil }
                return (type, data)
            })
        }

        pb.clearContents()
        write(pb)

        previousApp?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            synthesizeCommandV()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pb.clearContents()
                let items = snapshot.map { dict -> NSPasteboardItem in
                    let item = NSPasteboardItem()
                    for (type, data) in dict { item.setData(data, forType: type) }
                    return item
                }
                if !items.isEmpty { pb.writeObjects(items) }
            }
        }
    }

    private static func synthesizeCommandV() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode: CGKeyCode = 0x09
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
