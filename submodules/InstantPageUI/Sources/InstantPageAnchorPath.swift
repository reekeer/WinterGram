import Foundation
import TelegramCore

/// Recurses the `InstantPage` block tree to locate the anchor `name`, returning the
/// details-sibling-ordinal path of enclosing `<details>` blocks (outermost first).
///
/// - `nil`: the anchor does not exist.
/// - `[]`: the anchor is outside any `<details>`.
/// - `[2, 0]`: the third top-level `<details>`, then its first nested `<details>`.
///
/// Ordinals (not layout indices) because the layout's details index counter is
/// expansion-dependent. Consumers map ordinals to live indices via
/// `InstantPageV2View.firstCollapsedDetails(forOrdinalPath:)`.
public func instantPageAnchorPath(in instantPage: InstantPage, name: String) -> [Int]? {
    var ordinal = 0
    return instantPageAnchorPathSearch(instantPage.blocks, name: name, detailsOrdinal: &ordinal)
}

/// Searches `blocks` at a single details-nesting level. `detailsOrdinal` is the running count of
/// `<details>` blocks already passed at this level; container blocks that flatten in the layout
/// (`.blockQuote`/`.list`/`.cover`/`.postEmbed`) recurse sharing this counter, while a `<details>`
/// recurses with a fresh counter (a new level).
private func instantPageAnchorPathSearch(
    _ blocks: [InstantPageBlock],
    name: String,
    detailsOrdinal: inout Int
) -> [Int]? {
    for block in blocks {
        switch block {
        case let .anchor(anchorName):
            if anchorName == name { return [] }
        case let .title(text), let .subtitle(text), let .header(text), let .subheader(text),
             let .paragraph(text), let .footer(text), let .kicker(text), let .thinking(text):
            if richTextContainsAnchor(text, name: name) { return [] }
        case let .heading(text, _):
            if richTextContainsAnchor(text, name: name) { return [] }
        case let .authorDate(author, _):
            if richTextContainsAnchor(author, name: name) { return [] }
        case let .preformatted(text, _):
            if richTextContainsAnchor(text, name: name) { return [] }
        case let .pullQuote(text, caption):
            if richTextContainsAnchor(text, name: name) || richTextContainsAnchor(caption, name: name) { return [] }
        case let .details(title, childBlocks, _):
            if richTextContainsAnchor(title, name: name) { return [] }   // title is always laid out
            var childOrdinal = 0
            if let sub = instantPageAnchorPathSearch(childBlocks, name: name, detailsOrdinal: &childOrdinal) {
                return [detailsOrdinal] + sub
            }
            detailsOrdinal += 1
        case let .blockQuote(quoteBlocks, caption):
            if richTextContainsAnchor(caption, name: name) { return [] }
            if let r = instantPageAnchorPathSearch(quoteBlocks, name: name, detailsOrdinal: &detailsOrdinal) { return r }
        case let .list(items, _):
            for listItem in items {
                switch listItem {
                case let .text(text, _, _):
                    if richTextContainsAnchor(text, name: name) { return [] }
                case let .blocks(itemBlocks, _, _):
                    if let r = instantPageAnchorPathSearch(itemBlocks, name: name, detailsOrdinal: &detailsOrdinal) { return r }
                case .unknown:
                    break
                }
            }
        case let .cover(inner):
            if let r = instantPageAnchorPathSearch([inner], name: name, detailsOrdinal: &detailsOrdinal) { return r }
        case let .table(title, rows, _, _):
            if richTextContainsAnchor(title, name: name) { return [] }
            for row in rows {
                for cell in row.cells {
                    if let cellText = cell.text, richTextContainsAnchor(cellText, name: name) { return [] }
                }
            }
        default:
            // Keep recursion aligned with the V2 block layout.
            break
        }
    }
    return nil
}

/// True if the `RichText` tree contains an inline `.anchor` whose name equals `name`.
private func richTextContainsAnchor(_ text: RichText, name: String) -> Bool {
    switch text {
    case .empty, .plain, .image, .formula, .textCustomEmoji:
        return false
    case let .anchor(inner, anchorName):
        if anchorName == name { return true }
        return richTextContainsAnchor(inner, name: name)
    case let .concat(parts):
        for part in parts {
            if richTextContainsAnchor(part, name: name) { return true }
        }
        return false
    case let .bold(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .italic(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .underline(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .strikethrough(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .fixed(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .marked(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .`subscript`(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .superscript(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textAutoEmail(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textAutoPhone(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textAutoUrl(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textBankCard(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textBotCommand(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textCashtag(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textHashtag(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textMention(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .textSpoiler(inner):
        return richTextContainsAnchor(inner, name: name)
    case let .url(inner, _, _):
        return richTextContainsAnchor(inner, name: name)
    case let .email(inner, _):
        return richTextContainsAnchor(inner, name: name)
    case let .phone(inner, _):
        return richTextContainsAnchor(inner, name: name)
    case let .textMentionName(inner, _):
        return richTextContainsAnchor(inner, name: name)
    case let .textDate(inner, _, _):
        return richTextContainsAnchor(inner, name: name)
    }
}
