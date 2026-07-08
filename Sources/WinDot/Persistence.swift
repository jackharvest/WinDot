import AppKit
import Foundation

// MARK: - API key

enum APIKeyStore {
    static let configURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/gifpicker/config.json")

    /// GIPHY's publicly documented beta/sandbox test key. Fine for light personal use;
    /// if it ever gets rate-limited, get a free key at developers.giphy.com and drop it
    /// into ~/.config/gifpicker/config.json as {"apiKey": "YOUR_KEY"}.
    static let fallbackKey = "dc6zaTOxFJmzC"

    static func apiKey() -> String {
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let key = json["apiKey"], !key.isEmpty
        else {
            return fallbackKey
        }
        return key
    }

    static func save(_ key: String) {
        let dir = configURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: ["apiKey": key], options: .prettyPrinted) {
            try? data.write(to: configURL)
        }
    }
}

// MARK: - App settings (default tab)

enum AppearanceMode: String, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// nil means "don't override" — NSApp then just follows the system appearance.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

enum AppSettings {
    private static let defaultTabKey = "defaultTab"
    private static let appearanceModeKey = "appearanceMode"

    static var defaultTab: PickerTab {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultTabKey) else { return .combo }
            return PickerTab(rawValue: raw) ?? .combo
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultTabKey)
        }
    }

    static var appearanceMode: AppearanceMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: appearanceModeKey) else { return .system }
            return AppearanceMode(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appearanceModeKey)
        }
    }
}

// MARK: - Emoji usage ranking

enum EmojiUsageStore {
    private static let key = "emojiUsageCounts"

    private static func load() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return counts
    }

    private static func save(_ counts: [String: Int]) {
        guard let data = try? JSONEncoder().encode(counts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func record(_ emoji: String) {
        var counts = load()
        counts[emoji, default: 0] += 1
        save(counts)
    }

    /// Highest-count emoji first; ties keep the order UserDefaults' dictionary happens to
    /// give them (not meaningfully stable across launches, acceptable for a "top 10" list).
    static func topEmoji(limit: Int) -> [String] {
        load()
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}

// MARK: - Recently used GIFs

struct RecentGif: Codable, Identifiable, Equatable {
    let id: String
    let previewURL: URL
    let fullURL: URL

    var asResult: GifResult { GifResult(id: id, previewURL: previewURL, fullURL: fullURL) }
}

enum RecentGifsStore {
    private static let key = "recentGifs"
    private static let limit = 6

    static func load() -> [RecentGif] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let gifs = try? JSONDecoder().decode([RecentGif].self, from: data)
        else { return [] }
        return gifs
    }

    static func record(_ gif: RecentGif) {
        var gifs = load()
        gifs.removeAll { $0.id == gif.id }
        gifs.insert(gif, at: 0)
        if gifs.count > limit { gifs.removeLast(gifs.count - limit) }
        guard let data = try? JSONEncoder().encode(gifs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
