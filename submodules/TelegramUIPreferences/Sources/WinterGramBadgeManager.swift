import Foundation
import TelegramCore

public let winterGramBadgeManifestBaseURL = "https://raw.githubusercontent.com/reekeer/WinterGram/master/.wintergram/icons/"

public extension Notification.Name {
    static let winterGramBadgesChanged = Notification.Name("winterGramBadgesChanged")
}

public final class WinterGramBadgeManager {
    public static let shared = WinterGramBadgeManager()

    private let queue = DispatchQueue(label: "org.wintergram.badges", qos: .utility)
    private let lock = NSLock()
    private var _manifest: WinterGramBadgeManifest

    private let cacheDirectory: URL
    private let manifestCacheURL: URL
    private let refreshInterval: TimeInterval = 6.0 * 60.0 * 60.0
    private let requestTimeout: TimeInterval = 15.0
    private var timer: Timer?
    private var isRefreshing = false
    private var didStart = false

    private init() {
        let caches = (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = caches.appendingPathComponent("wintergram-badges", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        self.cacheDirectory = directory
        self.manifestCacheURL = directory.appendingPathComponent("manifest.json")

        if let data = try? Data(contentsOf: self.manifestCacheURL), let manifest = WinterGramBadgeManifest.decode(from: data) {
            self._manifest = manifest
        } else if let bundled = WinterGramBadgeManager.loadBundledManifest() {
            self._manifest = bundled
        } else {
            self._manifest = .empty
        }
    }

    private static func loadBundledManifest() -> WinterGramBadgeManifest? {
        guard let url = Bundle.main.url(forResource: "WinterGramBadgesManifest", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return WinterGramBadgeManifest.decode(from: data)
    }

    public var manifest: WinterGramBadgeManifest {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._manifest
    }

    public func badge(for peer: EnginePeer) -> WinterGramBadgeDef? {
        let rawId = peer.id.id._internalGetInt64Value()
        let manifest = self.manifest
        var best: WinterGramBadgeDef?
        for badge in manifest.badges {
            let matches: Bool
            switch peer {
            case .user:
                matches = badge.peers.users.contains(rawId)
            case .channel:
                matches = badge.peers.channels.contains(rawId)
            default:
                matches = false
            }
            if matches && (best == nil || badge.priority > best!.priority) {
                best = badge
            }
        }
        return best
    }

    public func localAssetFileURL(forSource source: String) -> URL? {
        let url = self.cacheDirectory.appendingPathComponent(WinterGramBadgeManager.sanitize(source))
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }

    private static func sanitize(_ source: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        let mapped = String(source.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
        return mapped.replacingOccurrences(of: "..", with: "_")
    }

    public func start() {
        self.queue.async {
            if self.didStart {
                return
            }
            self.didStart = true
            self.refreshLocked()
        }
        DispatchQueue.main.async {
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(withTimeInterval: self.refreshInterval, repeats: true, block: { [weak self] _ in
                    self?.refresh()
                })
            }
        }
    }

    public func refresh() {
        self.queue.async {
            self.refreshLocked()
        }
    }

    private func refreshLocked() {
        if self.isRefreshing {
            return
        }
        guard let manifestURL = URL(string: winterGramBadgeManifestBaseURL + "manifest.json"), manifestURL.scheme?.lowercased() == "https" else {
            return
        }
        self.isRefreshing = true

        var request = URLRequest(url: manifestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.requestTimeout)
        if let etag = UserDefaults.standard.string(forKey: "wnt_badge_etag") {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.queue.async {
                defer { strongSelf.isRefreshing = false }

                guard let http = response as? HTTPURLResponse else {
                    return
                }
                if http.statusCode == 304 {
                    return
                }
                guard http.statusCode == 200, let data = data, data.count <= WinterGramBadgeLimits.maxAssetBytes, let newManifest = WinterGramBadgeManifest.decode(from: data) else {
                    return
                }

                if newManifest.version <= strongSelf.manifest.version && newManifest == strongSelf.manifest {
                    return
                }

                strongSelf.downloadAssets(for: newManifest) {
                    try? data.write(to: strongSelf.manifestCacheURL, options: .atomic)
                    if let etag = http.value(forHTTPHeaderField: "Etag") {
                        UserDefaults.standard.set(etag, forKey: "wnt_badge_etag")
                    }
                    strongSelf.apply(newManifest)
                }
            }
        }.resume()
    }

    private func downloadAssets(for manifest: WinterGramBadgeManifest, completion: @escaping () -> Void) {
        let sources = manifest.assetSources.filter { self.localAssetFileURL(forSource: $0) == nil }
        guard !sources.isEmpty else {
            completion()
            return
        }
        let group = DispatchGroup()
        for source in sources {
            guard let url = URL(string: winterGramBadgeManifestBaseURL + source), url.scheme?.lowercased() == "https" else {
                continue
            }
            group.enter()
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.requestTimeout)
            URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
                defer { group.leave() }
                guard let strongSelf = self else {
                    return
                }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data, data.count <= WinterGramBadgeLimits.maxAssetBytes else {
                    return
                }
                let destination = strongSelf.cacheDirectory.appendingPathComponent(WinterGramBadgeManager.sanitize(source))
                try? data.write(to: destination, options: .atomic)
            }.resume()
        }
        group.notify(queue: self.queue) {
            completion()
        }
    }

    private func apply(_ manifest: WinterGramBadgeManifest) {
        self.lock.lock()
        self._manifest = manifest
        self.lock.unlock()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .winterGramBadgesChanged, object: nil)
        }
    }
}
