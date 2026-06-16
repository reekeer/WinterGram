import Foundation
import Postbox
import SwiftSignalKit

// A lightweight index of message ids that WinterGram kept after the peer deleted them.
// Stored in postbox preferences so the cache screen can show a count and purge them
// without scanning every chat.
public struct WinterGramDeletedMessagesIndex: Codable, Equatable {
    public struct Ref: Codable, Equatable {
        public var peerId: Int64
        public var namespace: Int32
        public var id: Int32
    }

    public var refs: [Ref]

    public init(refs: [Ref] = []) {
        self.refs = refs
    }
}

func winterGramRecordDeletedMessages(transaction: Transaction, ids: [MessageId]) {
    var index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
    var existing = Set(index.refs.map { "\($0.peerId):\($0.namespace):\($0.id)" })
    for id in ids {
        let key = "\(id.peerId.toInt64()):\(id.namespace):\(id.id)"
        if !existing.contains(key) {
            existing.insert(key)
            index.refs.append(WinterGramDeletedMessagesIndex.Ref(peerId: id.peerId.toInt64(), namespace: id.namespace, id: id.id))
        }
    }
    transaction.setPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages, value: PreferencesEntry(index))
}

public func winterGramDeletedMessagesCount(postbox: Postbox) -> Signal<Int, NoError> {
    return postbox.transaction { transaction -> Int in
        let index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
        return index.refs.count
    }
}

public func winterGramDeletedMessagesSize(postbox: Postbox) -> Signal<Int64, NoError> {
    return postbox.transaction { transaction -> Int64 in
        let index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
        var totalSize: Int64 = 0
        for ref in index.refs {
            guard let message = transaction.getMessage(MessageId(peerId: PeerId(ref.peerId), namespace: ref.namespace, id: ref.id)) else {
                continue
            }
            totalSize += Int64(message.text.utf8.count)
            for media in message.media {
                if let file = media as? TelegramMediaFile, let size = file.size {
                    totalSize += size
                }
            }
        }
        return totalSize
    }
}

public func winterGramClearDeletedMessages(postbox: Postbox) -> Signal<Int64, NoError> {
    return postbox.transaction { transaction -> Int64 in
        let index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
        let ids = index.refs.map { MessageId(peerId: PeerId($0.peerId), namespace: $0.namespace, id: $0.id) }
        var freedSize: Int64 = 0
        if !ids.isEmpty {
            for messageId in ids {
                guard let message = transaction.getMessage(messageId) else {
                    continue
                }
                freedSize += Int64(message.text.utf8.count)
                for media in message.media {
                    if let file = media as? TelegramMediaFile, let size = file.size {
                        freedSize += size
                    }
                }
            }
            transaction.deleteMessages(ids, forEachMedia: nil)
        }
        transaction.setPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages, value: PreferencesEntry(WinterGramDeletedMessagesIndex()))
        return freedSize
    }
}

public enum WinterGramDeletedMessageCategory: Int32, CaseIterable, Codable {
    case text
    case photo
    case video
    case voice
    case videoMessage
    case music
    case sticker
    case other
    
    public var titleKey: String {
        switch self {
        case .text:
            return "WinterGram.DeletedMessages.Text"
        case .photo:
            return "WinterGram.DeletedMessages.Photos"
        case .video:
            return "WinterGram.DeletedMessages.Videos"
        case .voice:
            return "WinterGram.DeletedMessages.Voice"
        case .videoMessage:
            return "WinterGram.DeletedMessages.VideoMessages"
        case .music:
            return "WinterGram.DeletedMessages.Music"
        case .sticker:
            return "WinterGram.DeletedMessages.Stickers"
        case .other:
            return "WinterGram.DeletedMessages.Other"
        }
    }
}

private func winterGramDeletedMessageCategory(for message: Message) -> WinterGramDeletedMessageCategory {
    if message.media.isEmpty {
        return .text
    }
    for media in message.media {
        if let file = media as? TelegramMediaFile {
            if file.isVoice {
                return .voice
            }
            if file.isInstantVideo {
                return .videoMessage
            }
            if file.isSticker {
                return .sticker
            }
            if file.isMusic {
                return .music
            }
            if file.isVideo || file.isAnimated {
                return .video
            }
            if file.mimeType.hasPrefix("image/") {
                return .photo
            }
            for attribute in file.attributes {
                if case .ImageSize = attribute {
                    return .photo
                }
            }
            return .other
        } else if media is TelegramMediaImage {
            return .photo
        }
    }
    return .other
}

public struct WinterGramDeletedMessagesStats: Codable, Equatable {
    public struct CategoryStat: Codable, Equatable {
        public var category: WinterGramDeletedMessageCategory
        public var count: Int
        public var size: Int64
        
        public init(category: WinterGramDeletedMessageCategory, count: Int, size: Int64) {
            self.category = category
            self.count = count
            self.size = size
        }
    }
    
    public struct TopChatStat: Codable, Equatable {
        public var peerId: Int64
        public var count: Int
        public var size: Int64
        
        public init(peerId: Int64, count: Int, size: Int64) {
            self.peerId = peerId
            self.count = count
            self.size = size
        }
    }
    
    public var categories: [CategoryStat]
    public var topChats: [TopChatStat]
    public var totalCount: Int
    public var totalSize: Int64
    
    public init(categories: [CategoryStat], topChats: [TopChatStat], totalCount: Int, totalSize: Int64) {
        self.categories = categories
        self.topChats = topChats
        self.totalCount = totalCount
        self.totalSize = totalSize
    }
}

public func winterGramDeletedMessagesStats(postbox: Postbox) -> Signal<WinterGramDeletedMessagesStats, NoError> {
    return postbox.transaction { transaction -> WinterGramDeletedMessagesStats in
        let index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
        var stats: [WinterGramDeletedMessageCategory: WinterGramDeletedMessagesStats.CategoryStat] = [:]
        var chatStats: [Int64: WinterGramDeletedMessagesStats.TopChatStat] = [:]
        var totalCount = 0
        var totalSize: Int64 = 0
        for ref in index.refs {
            guard let message = transaction.getMessage(MessageId(peerId: PeerId(ref.peerId), namespace: ref.namespace, id: ref.id)) else {
                continue
            }
            let category = winterGramDeletedMessageCategory(for: message)
            var size = Int64(message.text.utf8.count)
            for media in message.media {
                if let file = media as? TelegramMediaFile, let fileSize = file.size {
                    size += fileSize
                }
            }
            stats[category, default: WinterGramDeletedMessagesStats.CategoryStat(category: category, count: 0, size: 0)].count += 1
            stats[category, default: WinterGramDeletedMessagesStats.CategoryStat(category: category, count: 0, size: 0)].size += size
            chatStats[ref.peerId, default: WinterGramDeletedMessagesStats.TopChatStat(peerId: ref.peerId, count: 0, size: 0)].count += 1
            chatStats[ref.peerId, default: WinterGramDeletedMessagesStats.TopChatStat(peerId: ref.peerId, count: 0, size: 0)].size += size
            totalCount += 1
            totalSize += size
        }
        let topChats = chatStats.values.sorted { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count > rhs.count
            } else {
                return lhs.size > rhs.size
            }
        }.prefix(10).map { $0 }
        return WinterGramDeletedMessagesStats(
            categories: WinterGramDeletedMessageCategory.allCases.map { stats[$0] ?? WinterGramDeletedMessagesStats.CategoryStat(category: $0, count: 0, size: 0) },
            topChats: topChats,
            totalCount: totalCount,
            totalSize: totalSize
        )
    }
}

public func winterGramClearDeletedMessages(postbox: Postbox, categories: Set<WinterGramDeletedMessageCategory>) -> Signal<Int64, NoError> {
    return postbox.transaction { transaction -> Int64 in
        let index = transaction.getPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages)?.get(WinterGramDeletedMessagesIndex.self) ?? WinterGramDeletedMessagesIndex()
        var remainingRefs: [WinterGramDeletedMessagesIndex.Ref] = []
        var freedSize: Int64 = 0
        var deletedIds: [MessageId] = []
        for ref in index.refs {
            let messageId = MessageId(peerId: PeerId(ref.peerId), namespace: ref.namespace, id: ref.id)
            guard let message = transaction.getMessage(messageId) else {
                continue
            }
            let category = winterGramDeletedMessageCategory(for: message)
            if categories.contains(category) {
                var size = Int64(message.text.utf8.count)
                for media in message.media {
                    if let file = media as? TelegramMediaFile, let fileSize = file.size {
                        size += fileSize
                    }
                }
                freedSize += size
                deletedIds.append(messageId)
            } else {
                remainingRefs.append(ref)
            }
        }
        if !deletedIds.isEmpty {
            transaction.deleteMessages(deletedIds, forEachMedia: nil)
        }
        transaction.setPreferencesEntry(key: PreferencesKeys.winterGramDeletedMessages, value: PreferencesEntry(WinterGramDeletedMessagesIndex(refs: remainingRefs)))
        return freedSize
    }
}
