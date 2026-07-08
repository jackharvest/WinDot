import Foundation

// MARK: - Tabs

enum PickerTab: String, CaseIterable {
    case combo, gif, emoji

    var title: String {
        switch self {
        case .combo: return "Quick"
        case .gif: return "GIF"
        case .emoji: return "Emoji"
        }
    }

    var systemImage: String {
        switch self {
        case .combo: return "wand.and.stars"
        case .gif: return "photo.on.rectangle"
        case .emoji: return "face.smiling"
        }
    }
}

@MainActor
final class PickerModel: ObservableObject {
    @Published var query: String = ""
    @Published var emojiQuery: String = ""
    @Published var results: [GifResult] = []
    @Published var tab: PickerTab = AppSettings.defaultTab
    @Published var keyIsValid: Bool = true
    /// Mirrors whether the panel window is actually on screen. Drives whether
    /// AnimatedGifView instances animate — see AnimatedGifView.isActive.
    @Published var isPanelVisible: Bool = false
    /// Up-to-6 preview GIFs for the Combo tab's search state (separate from the paginated
    /// `results` used by the dedicated GIF tab).
    @Published var comboGifPreview: [GifResult] = []

    private let trendingCount = 6
    private let pageSize = 9
    private let comboPreviewCount = 6
    private var offset = 0
    private var isLoadingMore = false
    private var hasMore = true
    private var searchTask: Task<Void, Never>?

    private var isTrending: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func onQueryChanged() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            async let gifTab: () = reload()
            async let combo: () = reloadComboPreview()
            _ = await (gifTab, combo)
        }
    }

    func loadTrending() {
        guard results.isEmpty else { return }
        Task { await reload() }
    }

    /// Called every time the panel is summoned (not just first launch) so a frequent
    /// user never lands on a stale leftover search — always a blank, ready-to-type field
    /// and fresh trending results (cheap: served from GiphyCache almost every time).
    func resetForFreshOpen() {
        searchTask?.cancel()
        query = ""
        emojiQuery = ""
        results = []
        comboGifPreview = []
        offset = 0
        hasMore = true
        Task { await reload() }
    }

    /// Re-runs the current query. Called after the user saves a new API key from the
    /// setup card so the grid populates without needing to retype anything.
    func retry() {
        Task { await reload() }
    }

    private func reload() async {
        offset = 0
        hasMore = true
        let limit = isTrending ? trendingCount : pageSize
        let result = await GiphyClient.fetch(query: query, offset: 0, limit: limit)
        if Task.isCancelled { return }
        results = result.items
        keyIsValid = result.keyIsValid
        offset = result.items.count
    }

    private func reloadComboPreview() async {
        guard !isTrending else {
            comboGifPreview = []
            return
        }
        let result = await GiphyClient.fetch(query: query, offset: 0, limit: comboPreviewCount)
        if Task.isCancelled { return }
        comboGifPreview = result.items
    }

    func loadMoreIfNeeded(currentItem: GifResult) {
        guard !isTrending, !isLoadingMore, hasMore else { return }
        guard let idx = results.firstIndex(where: { $0.id == currentItem.id }) else { return }
        if idx >= results.count - 3 {
            Task { await loadMore() }
        }
    }

    private func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let result = await GiphyClient.fetch(query: query, offset: offset, limit: pageSize)
        if result.items.isEmpty { hasMore = false }
        results += result.items
        offset += result.items.count
        keyIsValid = result.keyIsValid
        isLoadingMore = false
    }
}
