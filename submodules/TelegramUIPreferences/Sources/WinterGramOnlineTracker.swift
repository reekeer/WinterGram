import Foundation

// WinterGram online/last-seen tracker storage.
//
// Records online<->offline transitions for peers while their chat is open. Backed by
// UserDefaults (this is a local, best-effort log, not synced). Each peer keeps the most
// recent `maxEntriesPerPeer` transitions. Used by the recorder in ChatController and the
// viewer in SettingsUI.

private let trackedPeersKey = "wnt_onlineTrackedPeers"
private func logKey(_ peerId: Int64) -> String { return "wnt_onlineLog_\(peerId)" }
private let maxEntriesPerPeer = 100

public struct WinterGramPresenceEntry: Equatable {
    public let timestamp: Int32
    public let isOnline: Bool
    public init(timestamp: Int32, isOnline: Bool) {
        self.timestamp = timestamp
        self.isOnline = isOnline
    }
}

/// Append a transition for `peerId` if it differs from the last recorded status.
public func winterGramRecordPresence(peerId: Int64, isOnline: Bool, timestamp: Int32 = Int32(Date().timeIntervalSince1970)) {
    let defaults = UserDefaults.standard
    var entries = winterGramPresenceLog(peerId: peerId)
    if let last = entries.last, last.isOnline == isOnline {
        return
    }
    entries.append(WinterGramPresenceEntry(timestamp: timestamp, isOnline: isOnline))
    if entries.count > maxEntriesPerPeer {
        entries.removeFirst(entries.count - maxEntriesPerPeer)
    }
    // Serialize as "timestamp:0/1" strings.
    let encoded = entries.map { "\($0.timestamp):\($0.isOnline ? 1 : 0)" }
    defaults.set(encoded, forKey: logKey(peerId))

    var tracked = Set(defaults.array(forKey: trackedPeersKey) as? [Int64] ?? (defaults.array(forKey: trackedPeersKey) as? [NSNumber])?.map { $0.int64Value } ?? [])
    if !tracked.contains(peerId) {
        tracked.insert(peerId)
        defaults.set(Array(tracked).map { NSNumber(value: $0) }, forKey: trackedPeersKey)
    }
}

public func winterGramPresenceLog(peerId: Int64) -> [WinterGramPresenceEntry] {
    guard let raw = UserDefaults.standard.array(forKey: logKey(peerId)) as? [String] else {
        return []
    }
    return raw.compactMap { item in
        let parts = item.split(separator: ":")
        guard parts.count == 2, let ts = Int32(parts[0]) else {
            return nil
        }
        return WinterGramPresenceEntry(timestamp: ts, isOnline: parts[1] == "1")
    }
}

/// All peer ids that have a recorded log, most-recently-active first.
public func winterGramTrackedPeerIds() -> [Int64] {
    let defaults = UserDefaults.standard
    let ids = (defaults.array(forKey: trackedPeersKey) as? [NSNumber])?.map { $0.int64Value } ?? []
    return ids.sorted { a, b in
        let la = winterGramPresenceLog(peerId: a).last?.timestamp ?? 0
        let lb = winterGramPresenceLog(peerId: b).last?.timestamp ?? 0
        return la > lb
    }
}

public func winterGramClearPresenceLog() {
    let defaults = UserDefaults.standard
    for id in winterGramTrackedPeerIds() {
        defaults.removeObject(forKey: logKey(id))
    }
    defaults.removeObject(forKey: trackedPeersKey)
}
