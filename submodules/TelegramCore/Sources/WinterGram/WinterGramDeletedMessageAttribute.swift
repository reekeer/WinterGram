import Foundation
import Postbox

// Marks a message that the peer deleted remotely but which WinterGram kept locally
// (the "save deleted messages" feature). The marker lets the cache screen enumerate and
// purge kept-deleted messages on demand. `date` is when the remote deletion arrived.
public class WinterGramDeletedMessageAttribute: MessageAttribute, Equatable {
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    required public init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("date", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "date")
    }

    public static func ==(lhs: WinterGramDeletedMessageAttribute, rhs: WinterGramDeletedMessageAttribute) -> Bool {
        return lhs.date == rhs.date
    }
}
