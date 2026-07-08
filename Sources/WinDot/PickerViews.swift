import AppKit
import SwiftUI

// MARK: - Animated GIF view (NSImageView animates multi-frame NSImage natively)

struct AnimatedGifView: NSViewRepresentable {
    let url: URL
    /// Mirrors PickerModel.isPanelVisible. When false, animation is paused (not torn
    /// down) so reopening the panel resumes instantly with zero idle CPU cost while hidden.
    var isActive: Bool = true

    final class Coordinator {
        var task: URLSessionDataTask?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = isActive
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.animates = isActive
        guard nsView.image == nil, context.coordinator.task == nil else { return }
        let task = URLSession.shared.dataTask(with: url) { [weak nsView] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                nsView?.image = image
            }
        }
        context.coordinator.task = task
        task.resume()
    }

    static func dismantleNSView(_ nsView: NSImageView, coordinator: Coordinator) {
        coordinator.task?.cancel()
    }
}

struct GifCell: View {
    let previewURL: URL
    let isActive: Bool
    var isSelected: Bool = false
    let onTap: () -> Void

    var body: some View {
        AnimatedGifView(url: previewURL, isActive: isActive)
            .frame(width: 100, height: 78)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}

struct EmojiCell: View {
    let emoji: String
    var isSelected: Bool = false
    let onTap: () -> Void

    var body: some View {
        Text(emoji)
            .font(.system(size: 22))
            .frame(width: 34, height: 34)
            .background(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}

struct SearchField: View {
    @Binding var query: String
    let status: String?
    let onChange: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search… (Esc to close)", text: $query)
                .textFieldStyle(.plain)
                .onChange(of: query) { _ in onChange() }
            if let status {
                Text(status).foregroundColor(.secondary).font(.caption)
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Tab bar

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title).font(.caption2)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle().fill(Color.accentColor).frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - API key onboarding

struct ApiKeySetupView: View {
    @State private var input: String = ""
    let onSave: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "key.slash")
                .font(.system(size: 26))
                .foregroundColor(.secondary)
            Text("GIF search needs a free GIPHY API key")
                .font(.headline)
            Text("Your key is missing, invalid, or rate-limited.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                TextField("Paste your API key here", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed)
                }
            }
            .frame(maxWidth: 260)

            Button("Get a free key at developers.giphy.com") {
                if let url = URL(string: "https://developers.giphy.com/dashboard/") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Horizontal scroll view that also accepts mouse-wheel input

/// Plain `NSScrollView` configured horizontal-only ignores vertical wheel ticks from
/// an ordinary mouse (only trackpads emit real `deltaX`), so this remaps a vertical
/// wheel event's delta onto the horizontal axis before handing it to AppKit's normal
/// scrolling machinery. Trackpad horizontal swipes (already non-zero `deltaX`) pass
/// through untouched.
final class WheelHorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        guard event.scrollingDeltaX == 0, event.scrollingDeltaY != 0,
              let cgEvent = event.cgEvent?.copy() else {
            super.scrollWheel(with: event)
            return
        }
        let verticalDelta = cgEvent.getDoubleValueField(.scrollWheelEventDeltaAxis1)
        let verticalPointDelta = cgEvent.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis1, value: 0)
        cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: verticalDelta)
        cgEvent.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
        cgEvent.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: verticalPointDelta)
        guard let remapped = NSEvent(cgEvent: cgEvent) else {
            super.scrollWheel(with: event)
            return
        }
        super.scrollWheel(with: remapped)
    }
}

/// Hosts SwiftUI `content` inside a `WheelHorizontalScrollView` so both trackpads and
/// ordinary scroll-wheel mice can pan it. `scrollTarget`, when it changes, scrolls the
/// minimum amount needed to bring that rect (in the content's own coordinate space)
/// into view — used to keep arrow-key selection in view.
struct HorizontalWheelScroll<Content: View>: NSViewRepresentable {
    var scrollTarget: CGRect?
    let content: Content

    init(scrollTarget: CGRect? = nil, @ViewBuilder content: () -> Content) {
        self.scrollTarget = scrollTarget
        self.content = content()
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?
        var lastScrollTarget: CGRect?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WheelHorizontalScrollView {
        let scrollView = WheelHorizontalScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = hosting
        context.coordinator.hostingView = hosting

        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hosting.heightAnchor.constraint(equalTo: scrollView.contentView.heightAnchor)
        ])
        return scrollView
    }

    func updateNSView(_ nsView: WheelHorizontalScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        if let scrollTarget, scrollTarget != context.coordinator.lastScrollTarget {
            context.coordinator.lastScrollTarget = scrollTarget
            context.coordinator.hostingView?.scrollToVisible(scrollTarget)
        }
    }
}

// MARK: - Combo tab (default): frequently-used emoji + recent/matching GIFs

/// Tab-key traversal order: search field -> emoji row -> GIF row (matches view order).
/// Arrow keys move a selection within whichever row currently holds this focus zone;
/// Return activates (pastes + closes) the selected item.
private enum ComboFocusZone: Hashable {
    case search, emojiRow, gifRow
}

struct ComboTabView: View {
    @ObservedObject var model: PickerModel
    let onPickGif: (GifResult) -> Void
    let onPickEmoji: (String) -> Void
    @Binding var status: String?
    let scheduleClose: (TimeInterval) -> Void

    @FocusState private var focusZone: ComboFocusZone?
    @State private var emojiIndex = 0
    @State private var gifIndex = 0

    private var trimmedQuery: String {
        model.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emojiMatches: [String] {
        trimmedQuery.isEmpty
            ? EmojiUsageStore.topEmoji(limit: 10)
            : EmojiData.search(trimmedQuery, limit: 10)
    }

    private var currentGifs: [GifResult] {
        if trimmedQuery.isEmpty {
            return RecentGifsStore.load().map { $0.asResult }
        }
        return model.keyIsValid ? model.comboGifPreview : []
    }

    /// Rect (in the GIF row's own coordinate space) of the currently keyboard-selected
    /// cell, matching GifCell's fixed 100pt width + the row's 6pt spacing — passed to
    /// HorizontalWheelScroll so arrow-key navigation scrolls the selection into view.
    private var gifScrollTarget: CGRect {
        let cellWidth: CGFloat = 100
        let spacing: CGFloat = 6
        let x = CGFloat(gifIndex) * (cellWidth + spacing)
        return CGRect(x: x, y: 0, width: cellWidth, height: 78)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchField(query: $model.query, status: status) { model.onQueryChanged() }
                .focused($focusZone, equals: .search)

            VStack(alignment: .leading, spacing: 4) {
                Text(trimmedQuery.isEmpty ? "Frequently Used" : "Matching Emoji")
                    .font(.caption).foregroundColor(.secondary)
                if emojiMatches.isEmpty {
                    Text(trimmedQuery.isEmpty ? "Pick some emoji to see your favorites here." : "No matches.")
                        .font(.caption2).foregroundColor(.secondary)
                } else {
                    // No scrolling here by design — emoji are cheap to re-search/retype,
                    // so overflow just truncates to the window's width instead of adding
                    // another scroll affordance.
                    HStack(spacing: 4) {
                        ForEach(Array(emojiMatches.enumerated()), id: \.offset) { index, emoji in
                            EmojiCell(emoji: emoji, isSelected: focusZone == .emojiRow && index == emojiIndex) {
                                activateEmoji(at: index)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .focusable()
                    .focused($focusZone, equals: .emojiRow)
                    .onMoveCommand { direction in
                        guard !emojiMatches.isEmpty else { return }
                        switch direction {
                        case .left: emojiIndex = max(0, emojiIndex - 1)
                        case .right: emojiIndex = min(emojiMatches.count - 1, emojiIndex + 1)
                        default: break
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trimmedQuery.isEmpty ? "Recent GIFs" : "Matching GIFs")
                    .font(.caption).foregroundColor(.secondary)
                if trimmedQuery.isEmpty, currentGifs.isEmpty {
                    Text("Pick a GIF to see it here next time.")
                        .font(.caption2).foregroundColor(.secondary)
                } else if !trimmedQuery.isEmpty, !model.keyIsValid {
                    Text("Add a GIPHY key on the GIF tab to see previews.")
                        .font(.caption2).foregroundColor(.secondary)
                } else if !trimmedQuery.isEmpty, currentGifs.isEmpty {
                    Text("No matches.").font(.caption2).foregroundColor(.secondary)
                } else {
                    HorizontalWheelScroll(scrollTarget: gifScrollTarget) {
                        HStack(spacing: 6) {
                            ForEach(Array(currentGifs.enumerated()), id: \.offset) { index, gif in
                                GifCell(
                                    previewURL: gif.previewURL,
                                    isActive: model.isPanelVisible,
                                    isSelected: focusZone == .gifRow && index == gifIndex
                                ) {
                                    activateGif(at: index)
                                }
                            }
                        }
                    }
                    .frame(height: 78)
                    .focusable()
                    .focused($focusZone, equals: .gifRow)
                    .onMoveCommand { direction in
                        guard !currentGifs.isEmpty else { return }
                        switch direction {
                        case .left: gifIndex = max(0, gifIndex - 1)
                        case .right: gifIndex = min(currentGifs.count - 1, gifIndex + 1)
                        default: break
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        // Invisible default-action button: Return activates whichever row zone has
        // keyboard focus. Fires window-wide (default-button semantics), so it's guarded
        // to no-op unless a row actually holds focus — typing Return in the search field
        // does nothing special.
        .background(
            Button("", action: activateFocusedSelection)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .frame(width: 0, height: 0)
                .opacity(0)
        )
        .onAppear { focusZone = .search }
        .onChange(of: model.isPanelVisible) { visible in
            if visible { focusZone = .search }
        }
        .onChange(of: model.query) { _ in
            emojiIndex = 0
            gifIndex = 0
        }
    }

    private func activateFocusedSelection() {
        switch focusZone {
        case .emojiRow: activateEmoji(at: emojiIndex)
        case .gifRow: activateGif(at: gifIndex)
        case .search, .none: break
        }
    }

    private func activateEmoji(at index: Int) {
        guard emojiMatches.indices.contains(index) else { return }
        onPickEmoji(emojiMatches[index])
        status = "Pasted!"
        scheduleClose(0.3)
    }

    private func activateGif(at index: Int) {
        guard currentGifs.indices.contains(index) else { return }
        onPickGif(currentGifs[index])
        status = "Pasted!"
        scheduleClose(0.4)
    }
}

// MARK: - Main picker view

struct GifPickerView: View {
    @ObservedObject var model: PickerModel
    let onPickGif: (GifResult) -> Void
    let onPickEmoji: (String) -> Void
    let onClose: () -> Void
    @State private var status: String?
    @FocusState private var searchFocused: Bool

    let gifColumns = [GridItem(.adaptive(minimum: 100), spacing: 6)]
    let emojiColumns = [GridItem(.adaptive(minimum: 30), spacing: 3)]

    private func scheduleClose(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            onClose()
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(PickerTab.allCases, id: \.self) { pickerTab in
                    TabButton(title: pickerTab.title, systemImage: pickerTab.systemImage, isSelected: model.tab == pickerTab) {
                        model.tab = pickerTab
                    }
                }
            }

            switch model.tab {
            case .combo:
                ComboTabView(model: model, onPickGif: onPickGif, onPickEmoji: onPickEmoji, status: $status, scheduleClose: scheduleClose)
            case .gif:
                gifTab
            case .emoji:
                emojiTab
            }
        }
        .padding(10)
        .frame(width: 360, height: 300)
        .background(.thinMaterial)
        // Ctrl+Tab / Ctrl+Shift+Tab cycle the main tab bar, browser-style — works from
        // any tab, independent of the Quick tab's own Tab-key row traversal (different
        // modifier, no conflict).
        .background(
            Group {
                Button("", action: { cycleTab(forward: true) })
                    .keyboardShortcut(.tab, modifiers: [.control])
                Button("", action: { cycleTab(forward: false) })
                    .keyboardShortcut(.tab, modifiers: [.control, .shift])
            }
            .buttonStyle(.plain)
            .frame(width: 0, height: 0)
            .opacity(0)
        )
        .onExitCommand { onClose() }
        .onChange(of: model.isPanelVisible) { visible in
            if visible { searchFocused = true }
        }
    }

    private func cycleTab(forward: Bool) {
        let all = PickerTab.allCases
        guard let idx = all.firstIndex(of: model.tab) else { return }
        let next = (idx + (forward ? 1 : -1) + all.count) % all.count
        model.tab = all[next]
    }

    @ViewBuilder
    private var gifTab: some View {
        if !model.keyIsValid {
            ApiKeySetupView { key in
                APIKeyStore.save(key)
                model.retry()
            }
            .onAppear { model.loadTrending() }
        } else {
            SearchField(query: $model.query, status: status) { model.onQueryChanged() }
                .focused($searchFocused)

            ScrollView {
                LazyVGrid(columns: gifColumns, spacing: 8) {
                    ForEach(model.results) { gif in
                        GifCell(previewURL: gif.previewURL, isActive: model.isPanelVisible) {
                            onPickGif(gif)
                            status = "Pasted!"
                            scheduleClose(0.4)
                        }
                        .onAppear { model.loadMoreIfNeeded(currentItem: gif) }
                    }
                }
            }
            .onAppear { model.loadTrending() }
        }
    }

    private var emojiTab: some View {
        let trimmed = model.emojiQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(spacing: 8) {
            SearchField(query: $model.emojiQuery, status: status) { }
                .focused($searchFocused)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !trimmed.isEmpty {
                        let matches = EmojiData.search(trimmed, limit: 80)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Results").font(.caption).foregroundColor(.secondary)
                            if matches.isEmpty {
                                Text("No matches.").font(.caption2).foregroundColor(.secondary)
                            } else {
                                LazyVGrid(columns: emojiColumns, spacing: 4) {
                                    ForEach(matches, id: \.self) { emoji in
                                        EmojiCell(emoji: emoji) {
                                            onPickEmoji(emoji)
                                            status = "Pasted!"
                                            scheduleClose(0.3)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        let frequent = EmojiUsageStore.topEmoji(limit: 10)
                        if !frequent.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Frequently Used").font(.caption).foregroundColor(.secondary)
                                LazyVGrid(columns: emojiColumns, spacing: 4) {
                                    ForEach(frequent, id: \.self) { emoji in
                                        EmojiCell(emoji: emoji) {
                                            onPickEmoji(emoji)
                                            status = "Pasted!"
                                            scheduleClose(0.3)
                                        }
                                    }
                                }
                            }
                        }
                        ForEach(EmojiData.categories, id: \.category) { category, emojis in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category).font(.caption).foregroundColor(.secondary)
                                LazyVGrid(columns: emojiColumns, spacing: 4) {
                                    ForEach(emojis, id: \.emoji) { entry in
                                        EmojiCell(emoji: entry.emoji) {
                                            onPickEmoji(entry.emoji)
                                            status = "Pasted!"
                                            scheduleClose(0.3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
