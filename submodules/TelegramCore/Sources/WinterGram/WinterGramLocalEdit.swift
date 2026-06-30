import Foundation
import Postbox
import SwiftSignalKit

// Replaces a message's text locally without a network edit, so the
// server never learns about the change and no "edited" mark is added. The change
// persists in the local database until the message is re-fetched from the server.
public func winterGramEditMessageLocally(postbox: Postbox, messageId: MessageId, text: String) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updateMessage(messageId, update: { currentMessage in
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }

            var attributes = currentMessage.attributes
            attributes.removeAll(where: { $0 is TextEntitiesMessageAttribute })

            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: text, attributes: attributes, media: currentMessage.media))
        })
    }
}
