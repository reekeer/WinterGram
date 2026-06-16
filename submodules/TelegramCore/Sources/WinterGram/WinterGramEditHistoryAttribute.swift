import Foundation
import Postbox

public class WinterGramEditHistoryAttribute: MessageAttribute, Equatable {
    public struct Revision: PostboxCoding, Equatable {
        public let text: String
        public let entities: [MessageTextEntity]
        public let timestamp: Int32

        public init(text: String, entities: [MessageTextEntity], timestamp: Int32) {
            self.text = text
            self.entities = entities
            self.timestamp = timestamp
        }

        public init(decoder: PostboxDecoder) {
            self.text = decoder.decodeStringForKey("text", orElse: "")
            self.entities = decoder.decodeObjectArrayWithDecoderForKey("entities")
            self.timestamp = decoder.decodeInt32ForKey("timestamp", orElse: 0)
        }

        public func encode(_ encoder: PostboxEncoder) {
            encoder.encodeString(self.text, forKey: "text")
            encoder.encodeObjectArray(self.entities, forKey: "entities")
            encoder.encodeInt32(self.timestamp, forKey: "timestamp")
        }
    }

    public let revisions: [Revision]

    public init(revisions: [Revision]) {
        self.revisions = revisions
    }

    required public init(decoder: PostboxDecoder) {
        self.revisions = decoder.decodeObjectArrayWithDecoderForKey("revisions")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeObjectArray(self.revisions, forKey: "revisions")
    }

    public static func ==(lhs: WinterGramEditHistoryAttribute, rhs: WinterGramEditHistoryAttribute) -> Bool {
        return lhs.revisions == rhs.revisions
    }
}
