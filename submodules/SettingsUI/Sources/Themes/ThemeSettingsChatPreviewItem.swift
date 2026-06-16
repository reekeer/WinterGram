import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import WallpaperBackgroundNode
import AvatarNode

struct ChatPreviewMessageItem: Equatable {
    static func == (lhs: ChatPreviewMessageItem, rhs: ChatPreviewMessageItem) -> Bool {
        if lhs.outgoing != rhs.outgoing {
            return false
        }
        if let lhsReply = lhs.reply, let rhsReply = rhs.reply, lhsReply.0 != rhsReply.0 || lhsReply.1 != rhsReply.1 {
            return false
        } else if (lhs.reply == nil) != (rhs.reply == nil) {
            return false
        }
        if lhs.text != rhs.text {
            return false
        }
        if lhs.nameColor != rhs.nameColor {
            return false
        }
        if lhs.photo != rhs.photo {
            return false
        }
        if lhs.backgroundEmojiId != rhs.backgroundEmojiId {
            return false
        }
        return true
    }

    let outgoing: Bool
    let reply: (String, String)?
    let text: String
    let nameColor: PeerColor
    var photo: [TelegramMediaImageRepresentation] = []
    let backgroundEmojiId: Int64?
}

class ThemeSettingsChatPreviewItem: ListViewItem, ItemListItem {
    let context: AccountContext
    let systemStyle: ItemListSystemStyle
    let theme: PresentationTheme
    let componentTheme: PresentationTheme
    let strings: PresentationStrings
    let sectionId: ItemListSectionId
    let fontSize: PresentationFontSize
    let chatBubbleCorners: PresentationChatBubbleCorners
    let wallpaper: TelegramWallpaper
    let dateTimeFormat: PresentationDateTimeFormat
    let nameDisplayOrder: PresentationPersonNameOrder
    let messageItems: [ChatPreviewMessageItem]
    let avatarCornerRadius: Int32
    let avatarPeer: EnginePeer?

    init(context: AccountContext, systemStyle: ItemListSystemStyle = .legacy, theme: PresentationTheme, componentTheme: PresentationTheme, strings: PresentationStrings, sectionId: ItemListSectionId, fontSize: PresentationFontSize, chatBubbleCorners: PresentationChatBubbleCorners, wallpaper: TelegramWallpaper, dateTimeFormat: PresentationDateTimeFormat, nameDisplayOrder: PresentationPersonNameOrder, messageItems: [ChatPreviewMessageItem], avatarCornerRadius: Int32 = currentWinterGramSettings.avatarCornerRadius, avatarPeer: EnginePeer? = nil) {
        self.context = context
        self.systemStyle = systemStyle
        self.theme = theme
        self.componentTheme = componentTheme
        self.strings = strings
        self.sectionId = sectionId
        self.fontSize = fontSize
        self.chatBubbleCorners = chatBubbleCorners
        self.wallpaper = wallpaper
        self.dateTimeFormat = dateTimeFormat
        self.nameDisplayOrder = nameDisplayOrder
        self.messageItems = messageItems
        self.avatarCornerRadius = avatarCornerRadius
        self.avatarPeer = avatarPeer
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = ThemeSettingsChatPreviewItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ThemeSettingsChatPreviewItemNode {
                let makeLayout = nodeValue.asyncLayout()

                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
}

class ThemeSettingsChatPreviewItemNode: ListViewItemNode {
    private var backgroundNode: WallpaperBackgroundNode?
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let avatarNode: AvatarNode

    private let containerNode: ASDisplayNode
    private var messageNodes: [ListViewItemNode]?

    private var item: ThemeSettingsChatPreviewItem?
    private var finalImage = true

    private let disposable = MetaDisposable()

    init() {
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true

        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true

        self.maskNode = ASImageNode()
        self.avatarNode = AvatarNode(font: avatarPlaceholderFont(size: 15.0))
        self.avatarNode.isUserInteractionEnabled = false

        self.containerNode = ASDisplayNode()
        self.containerNode.subnodeTransform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)

        super.init(layerBacked: false)

        self.clipsToBounds = true

        self.addSubnode(self.containerNode)
        self.addSubnode(self.avatarNode)
    }

    deinit {
        self.disposable.dispose()
    }

    func asyncLayout() -> (_ item: ThemeSettingsChatPreviewItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentNodes = self.messageNodes
        let currentItem = self.item

        var currentBackgroundNode = self.backgroundNode

        return { item, params, neighbors in
            let canReuseCurrentNodes = currentItem?.avatarCornerRadius == item.avatarCornerRadius

            if currentBackgroundNode == nil {
                // WallpaperBackgroundNodeImpl.init touches `self.view` (portal source views), which asserts
                // off the main thread. asyncLayout runs on a background queue, so create it on main.
                if Thread.isMainThread {
                    currentBackgroundNode = createWallpaperBackgroundNode(context: item.context, forChatDisplay: false)
                } else {
                    let context = item.context
                    let semaphore = DispatchSemaphore(value: 0)
                    var createdNode: WallpaperBackgroundNode?
                    Queue.mainQueue().async {
                        createdNode = createWallpaperBackgroundNode(context: context, forChatDisplay: false)
                        semaphore.signal()
                    }
                    semaphore.wait()
                    currentBackgroundNode = createdNode
                }
            }
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel

            // Use a fake group chat so incoming preview messages render author avatars
            // (private-chat previews intentionally hide avatars; group/channel previews show them).
            let chatPeerId = EnginePeer.Id(namespace: Namespaces.Peer.CloudGroup, id: EnginePeer.Id.Id._internalFromInt64Value(1))
            let incomingAuthorId = EnginePeer.Id(namespace: Namespaces.Peer.CloudUser, id: EnginePeer.Id.Id._internalFromInt64Value(2))
            let outgoingAuthorId = EnginePeer.Id(namespace: Namespaces.Peer.CloudUser, id: EnginePeer.Id.Id._internalFromInt64Value(3))

            let chatPeer = TelegramGroup(id: chatPeerId, title: "Preview", photo: [], participantCount: 2, role: .member, membership: .Member, flags: TelegramGroupFlags(), defaultBannedRights: nil, migrationReference: nil, creationDate: 0, version: 0)
            let outgoingAuthor = TelegramUser(id: outgoingAuthorId, accessHash: nil, firstName: "", lastName: "", username: nil, phone: nil, photo: [], botInfo: nil, restrictionInfo: nil, flags: [], emojiStatus: nil, usernames: [], storiesHidden: nil, nameColor: nil, backgroundEmojiId: nil, profileColor: nil, profileBackgroundEmojiId: nil, subscriberCount: nil, verificationIconFileId: nil)

            var items: [ListViewItem] = []
            for messageItem in item.messageItems.reversed() {
                var peers = EngineSimpleDictionary<EnginePeer.Id, EngineRawPeer>()
                peers[chatPeerId] = chatPeer
                var messages = EngineSimpleDictionary<EngineMessage.Id, EngineRawMessage>()

                let replyMessageId = EngineMessage.Id(peerId: chatPeerId, namespace: 0, id: 3)
                if let (author, text) = messageItem.reply {
                    let replyAuthor = TelegramUser(id: incomingAuthorId, accessHash: nil, firstName: author, lastName: "", username: nil, phone: nil, photo: messageItem.photo, botInfo: nil, restrictionInfo: nil, flags: [], emojiStatus: nil, usernames: [], storiesHidden: nil, nameColor: messageItem.nameColor, backgroundEmojiId: messageItem.backgroundEmojiId, profileColor: nil, profileBackgroundEmojiId: nil, subscriberCount: nil, verificationIconFileId: nil)
                    peers[incomingAuthorId] = replyAuthor
                    messages[replyMessageId] = EngineRawMessage(stableId: 3, stableVersion: 0, id: replyMessageId, globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 66000, flags: [.Incoming], tags: [], globalTags: [], localTags: [], customTags: [], forwardInfo: nil, author: replyAuthor, text: text, attributes: [], media: [], peers: peers, associatedMessages: EngineSimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil, associatedStories: [:])
                }

                let author: EngineRawPeer
                if messageItem.outgoing {
                    author = outgoingAuthor
                } else {
                    author = TelegramUser(id: incomingAuthorId, accessHash: nil, firstName: "Winter", lastName: "Gram", username: nil, phone: nil, photo: messageItem.photo, botInfo: nil, restrictionInfo: nil, flags: [], emojiStatus: nil, usernames: [], storiesHidden: nil, nameColor: messageItem.nameColor, backgroundEmojiId: messageItem.backgroundEmojiId, profileColor: nil, profileBackgroundEmojiId: nil, subscriberCount: nil, verificationIconFileId: nil)
                }
                peers[author.id] = author

                let message = EngineRawMessage(stableId: 1, stableVersion: 0, id: EngineMessage.Id(peerId: chatPeerId, namespace: 0, id: 1), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 66000, flags: messageItem.outgoing ? [] : [.Incoming], tags: [], globalTags: [], localTags: [], customTags: [], forwardInfo: nil, author: author, text: messageItem.text, attributes: messageItem.reply != nil ? [ReplyMessageAttribute(messageId: replyMessageId, threadMessageId: nil, quote: nil, isQuote: false, innerSubject: nil)] : [], media: [], peers: peers, associatedMessages: messages, associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil, associatedStories: [:])
                items.append(item.context.sharedContext.makeChatMessagePreviewItem(context: item.context, messages: [message], theme: item.componentTheme, strings: item.strings, wallpaper: item.wallpaper, fontSize: item.fontSize, chatBubbleCorners: item.chatBubbleCorners, dateTimeFormat: item.dateTimeFormat, nameOrder: item.nameDisplayOrder, forcedResourceStatus: nil, tapMessage: nil, clickThroughMessage: nil, backgroundNode: currentBackgroundNode, availableReactions: nil, accountPeer: outgoingAuthor, isCentered: false, isPreview: true, isStandalone: false, rank: nil, rankRole: nil))
            }

            var nodes: [ListViewItemNode] = []
            if let messageNodes = currentNodes, canReuseCurrentNodes {
                nodes = messageNodes
                for i in 0 ..< items.count {
                    let itemNode = messageNodes[i]
                    items[i].updateNode(async: { $0() }, node: {
                        return itemNode
                    }, params: params, previousItem: i == 0 ? nil : items[i - 1], nextItem: i == (items.count - 1) ? nil : items[i + 1], animation: .None, completion: { (layout, apply) in
                        let nodeFrame = CGRect(origin: itemNode.frame.origin, size: CGSize(width: layout.size.width, height: layout.size.height))

                        itemNode.contentSize = layout.contentSize
                        itemNode.insets = layout.insets
                        itemNode.frame = nodeFrame
                        itemNode.isUserInteractionEnabled = false

                        apply(ListViewItemApply(isOnScreen: true))
                    })
                }
            } else {
                var messageNodes: [ListViewItemNode] = []
                for i in 0 ..< items.count {
                    var itemNode: ListViewItemNode?
                    items[i].nodeConfiguredForParams(async: { $0() }, params: params, synchronousLoads: false, previousItem: i == 0 ? nil : items[i - 1], nextItem: i == (items.count - 1) ? nil : items[i + 1], completion: { node, apply in
                        itemNode = node
                        apply().1(ListViewItemApply(isOnScreen: true))
                    })
                    itemNode!.isUserInteractionEnabled = false
                    messageNodes.append(itemNode!)
                }
                nodes = messageNodes
            }

            var contentSize = CGSize(width: params.width, height: 4.0 + 4.0)
            for node in nodes {
                contentSize.height += node.frame.size.height
            }
            insets = itemListNeighborsGroupedInsets(neighbors, params)

            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size

            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item

                    strongSelf.containerNode.frame = CGRect(origin: CGPoint(), size: contentSize)

                    if !canReuseCurrentNodes {
                        currentNodes?.forEach { $0.removeFromSupernode() }
                    }
                    strongSelf.messageNodes = nodes
                    var topOffset: CGFloat = 4.0
                    var avatarFrame: CGRect?
                    let displayedMessageItems = Array(item.messageItems.reversed())
                    for (nodeIndex, node) in nodes.enumerated() {
                        if node.supernode == nil {
                            strongSelf.containerNode.addSubnode(node)
                        }
                        node.updateFrame(CGRect(origin: CGPoint(x: 0.0, y: topOffset), size: node.frame.size), within: layoutSize)
                        if avatarFrame == nil, nodeIndex < displayedMessageItems.count, !displayedMessageItems[nodeIndex].outgoing {
                            let avatarSize: CGFloat = 40.0
                            avatarFrame = CGRect(
                                x: params.leftInset + 9.0,
                                y: topOffset + max(6.0, node.frame.height - avatarSize - 8.0),
                                width: avatarSize,
                                height: avatarSize
                            )
                        }
                        topOffset += node.frame.size.height
                    }
                    if let avatarPeer = item.avatarPeer, let avatarFrame {
                        strongSelf.avatarNode.isHidden = false
                        strongSelf.avatarNode.frame = avatarFrame
                        let avatarRadius = min(avatarFrame.width, avatarFrame.height) * CGFloat(max(0, min(50, item.avatarCornerRadius))) / 100.0
                        strongSelf.avatarNode.layer.cornerRadius = avatarRadius
                        strongSelf.avatarNode.layer.masksToBounds = true
                        strongSelf.avatarNode.setPeer(context: item.context, theme: item.componentTheme, peer: avatarPeer, synchronousLoad: false, displayDimensions: avatarFrame.size)
                        strongSelf.avatarNode.updateSize(size: avatarFrame.size)
                    } else {
                        strongSelf.avatarNode.isHidden = true
                    }

                    if let currentBackgroundNode = currentBackgroundNode, strongSelf.backgroundNode !== currentBackgroundNode {
                        strongSelf.backgroundNode = currentBackgroundNode
                        strongSelf.insertSubnode(currentBackgroundNode, at: 0)
                    }
                    currentBackgroundNode?.update(wallpaper: item.wallpaper, animated: false)
                    currentBackgroundNode?.updateBubbleTheme(bubbleTheme: item.componentTheme, bubbleCorners: item.chatBubbleCorners)

                    strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor

                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    if strongSelf.maskNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                    }

                    let hasCorners = itemListHasRoundedBlockLayout(params)
                    var hasTopCorners = false
                    var hasBottomCorners = false
                    switch neighbors.top {
                        case .sameSection(false):
                            strongSelf.topStripeNode.isHidden = true
                        default:
                            hasTopCorners = true
                            strongSelf.topStripeNode.isHidden = hasCorners
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                        case .sameSection(false):
                            bottomStripeInset = 0.0
                            bottomStripeOffset = -separatorHeight
                            strongSelf.bottomStripeNode.isHidden = false
                        default:
                            bottomStripeInset = 0.0
                            bottomStripeOffset = 0.0
                            hasBottomCorners = true
                            strongSelf.bottomStripeNode.isHidden = hasCorners
                    }

                    strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.componentTheme, top: hasTopCorners, bottom: hasBottomCorners, glass: item.systemStyle == .glass) : nil

                    let backgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))

                    let displayMode: WallpaperDisplayMode
                    if abs(params.availableHeight - params.width) < 100.0, params.availableHeight > 700.0 {
                        displayMode = .halfAspectFill
                    } else {
                        if backgroundFrame.width > backgroundFrame.height * 4.0 {
                            if params.availableHeight < 700.0 {
                                displayMode = .halfAspectFill
                            } else {
                                displayMode = .aspectFill
                            }
                        } else {
                            displayMode = .aspectFill
                        }
                    }

                    if let backgroundNode = strongSelf.backgroundNode {
                        backgroundNode.frame = backgroundFrame.insetBy(dx: 0.0, dy: -100.0)
                        backgroundNode.updateLayout(size: backgroundNode.bounds.size, displayMode: displayMode, transition: .immediate)
                    }
                    strongSelf.maskNode.frame = backgroundFrame.insetBy(dx: params.leftInset, dy: 0.0)
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                }
            })
        }
    }

    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
