import Foundation

// MARK: - GIPHY client

struct GifResult: Identifiable, Decodable {
    let id: String
    let previewURL: URL
    let fullURL: URL

    init(id: String, previewURL: URL, fullURL: URL) {
        self.id = id
        self.previewURL = previewURL
        self.fullURL = fullURL
    }

    private enum RootKeys: String, CodingKey { case id, images }
    private enum ImagesKeys: String, CodingKey {
        case fixed_width_small, original
    }
    private enum VariantKeys: String, CodingKey { case url }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        id = try root.decode(String.self, forKey: .id)
        let images = try root.nestedContainer(keyedBy: ImagesKeys.self, forKey: .images)
        let preview = try images.nestedContainer(keyedBy: VariantKeys.self, forKey: .fixed_width_small)
        let original = try images.nestedContainer(keyedBy: VariantKeys.self, forKey: .original)
        previewURL = URL(string: try preview.decode(String.self, forKey: .url))!
        fullURL = URL(string: try original.decode(String.self, forKey: .url))!
    }

    var asRecent: RecentGif { RecentGif(id: id, previewURL: previewURL, fullURL: fullURL) }
}

private struct GiphyMeta: Decodable {
    let status: Int
    let msg: String?
}

private struct GiphyResponse: Decodable {
    let data: [GifResult]
    let meta: GiphyMeta
}

// MARK: - Session-only response cache

/// Keeps repeat searches (the same favorite phrase typed again, or reopening the picker
/// and re-searching) from burning through GIPHY's 100-calls/hr free-tier limit. In-memory
/// only — resets on quit, which is fine since the point is smoothing out a single session's
/// back-and-forth, not building a permanent offline cache.
actor GiphyCache {
    static let shared = GiphyCache()

    private struct Entry {
        let result: GiphyClient.FetchResult
        let storedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private let ttl: TimeInterval = 15 * 60
    private let capacity = 60

    func get(_ key: String) -> GiphyClient.FetchResult? {
        guard let entry = entries[key], Date().timeIntervalSince(entry.storedAt) < ttl else { return nil }
        return entry.result
    }

    func set(_ key: String, _ result: GiphyClient.FetchResult) {
        if entries.count >= capacity, let oldest = entries.min(by: { $0.value.storedAt < $1.value.storedAt })?.key {
            entries.removeValue(forKey: oldest)
        }
        entries[key] = Entry(result: result, storedAt: Date())
    }
}

enum GiphyClient {
    struct FetchResult {
        let items: [GifResult]
        /// false only when GIPHY itself rejected the key (403/401); nil-on-network-error
        /// cases are treated as "unknown" (true) so a dropped connection doesn't get
        /// mistaken for a bad key and flash the setup card.
        let keyIsValid: Bool
    }

    static func fetch(query: String, offset: Int, limit: Int) async -> FetchResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(trimmed.lowercased())|\(offset)|\(limit)"
        if let cached = await GiphyCache.shared.get(cacheKey) {
            return cached
        }

        let key = APIKeyStore.apiKey()
        let endpoint = trimmed.isEmpty
            ? "https://api.giphy.com/v1/gifs/trending"
            : "https://api.giphy.com/v1/gifs/search"
        var components = URLComponents(string: endpoint)!
        var items = [
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "q", value: trimmed))
        }
        components.queryItems = items

        guard let url = components.url else { return FetchResult(items: [], keyIsValid: true) }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(GiphyResponse.self, from: data)
            let result = FetchResult(items: decoded.data, keyIsValid: decoded.meta.status == 200)
            if decoded.meta.status == 200 {
                await GiphyCache.shared.set(cacheKey, result)
            }
            return result
        } catch {
            print("GIPHY search failed: \(error)")
            return FetchResult(items: [], keyIsValid: true)
        }
    }
}
