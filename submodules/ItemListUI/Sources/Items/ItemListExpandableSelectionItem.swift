import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AppBundle
import CheckNode

// An expandable row for options: single-select radio-style or multi-select checkbox-style.
// The header shows the selected value (single) or a count (multi), and the inline sub-items use
// square checkbox visuals. In multi-select mode the menu stays open after a tap.
public class ItemListExpandableSelectionItem: ListViewItem, ItemListItem {
    public enum SelectionMode {
        case single
        case multiple
    }

    public struct Option: Equatable {
        public var id: AnyHashable
        public var title: String
        public var isSelected: Bool
        public var index: Int
        
        public init(id: AnyHashable, title: String, isSelected: Bool, index: Int = 0) {
            self.id = id
            self.title = title
            self.isSelected = isSelected
            self.index = index
        }
    }
    
    public let presentationData: ItemListPresentationData
    public let systemStyle: ItemListSystemStyle
    public let title: String
    public let options: [Option]
    public let mode: SelectionMode
    public let isExpanded: Bool
    public let sectionId: ItemListSectionId
    public let style: ItemListStyle
    public let updated: (Option) -> Void
    public let toggleExpanded: () -> Void
    public let tag: ItemListItemTag?

    public var isAlwaysPlain: Bool { return false }
    public let selectable: Bool = true

    public init(presentationData: ItemListPresentationData, systemStyle: ItemListSystemStyle = .legacy, title: String, options: [Option], mode: SelectionMode = .single, isExpanded: Bool, sectionId: ItemListSectionId, style: ItemListStyle, updated: @escaping (Option) -> Void, toggleExpanded: @escaping () -> Void = {}, tag: ItemListItemTag? = nil) {
        self.presentationData = presentationData
        self.systemStyle = systemStyle
        self.title = title
        self.options = options
        self.mode = mode
        self.isExpanded = isExpanded
        self.sectionId = sectionId
        self.style = style
        self.updated = updated
        self.toggleExpanded = toggleExpanded
        self.tag = tag
    }
    
    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = ItemListExpandableSelectionItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply(ListViewItemUpdateAnimation.None) })
                })
            }
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ItemListExpandableSelectionItemNode {
                let makeLayout = nodeValue.asyncLayout()
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply(animation)
                        })
                    }
                }
            }
        }
    }
    
    public func selected(listView: ListView) {
        listView.clearHighlightAnimated(true)
        // Tapping the header row toggles the inline option list open/closed.
        self.toggleExpanded()
    }
}

private final class SelectionOptionNode: HighlightTrackingButtonNode {
    private let textNode: ImmediateTextNode
    private var checkNode: CheckNode?
    private let separatorNode: ASDisplayNode
    
    private var theme: PresentationTheme?
    private var option: ItemListExpandableSelectionItem.Option?
    private var action: ((ItemListExpandableSelectionItem.Option) -> Void)?
    
    init() {
        self.textNode = ImmediateTextNode()
        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        super.init()
        self.addSubnode(self.separatorNode)
        self.addSubnode(self.textNode)
        self.addTarget(self, action: #selector(self.pressed), forControlEvents: .touchUpInside)
    }
    
    @objc private func pressed() {
        guard let option = self.option, let action = self.action else {
            return
        }
        action(option)
    }
    
    func update(presentationData: ItemListPresentationData, option: ItemListExpandableSelectionItem.Option, action: @escaping (ItemListExpandableSelectionItem.Option) -> Void, size: CGSize, transition: ContainedViewLayoutTransition) {
        let themeUpdated = self.theme !== presentationData.theme
        self.option = option
        self.action = action
        let leftInset: CGFloat = 60.0
        if themeUpdated {
            self.separatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
        }
        let checkNode: CheckNode
        if let current = self.checkNode {
            checkNode = current
            if themeUpdated {
                checkNode.theme = CheckNodeTheme(theme: presentationData.theme, style: .plain)
            }
        } else {
            checkNode = CheckNode(theme: CheckNodeTheme(theme: presentationData.theme, style: .plain), content: .check(isRectangle: true))
            checkNode.isUserInteractionEnabled = false
            self.checkNode = checkNode
            self.addSubnode(checkNode)
        }
        let checkSize = CGSize(width: 22.0, height: 22.0)
        checkNode.frame = CGRect(origin: CGPoint(x: floor((leftInset - checkSize.width) / 2.0), y: floor((size.height - checkSize.height) / 2.0)), size: checkSize)
        checkNode.setSelected(option.isSelected, animated: transition.isAnimated)
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(x: leftInset, y: size.height - UIScreenPixel), size: CGSize(width: size.width - leftInset - 16.0, height: UIScreenPixel)))
        self.textNode.attributedText = NSAttributedString(string: option.title, font: Font.regular(17.0), textColor: presentationData.theme.list.itemPrimaryTextColor)
        let titleSize = self.textNode.updateLayout(CGSize(width: size.width - leftInset, height: 100.0))
        self.textNode.frame = CGRect(origin: CGPoint(x: leftInset, y: floor((size.height - titleSize.height) / 2.0)), size: titleSize)
    }
}

public class ItemListExpandableSelectionItemNode: ListViewItemNode, ItemListItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomTopStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let highlightedBackgroundNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    private let titleNode: TextNode
    private let titleValueNode: TextNode
    private let expandArrowNode: ASImageNode
    private let subItemContainer: ASDisplayNode
    private var subItemNodes: [AnyHashable: SelectionOptionNode] = [:]
    private let activateArea: AccessibilityAreaNode
    
    private var item: ItemListExpandableSelectionItem?
    
    public var tag: ItemListItemTag? {
        return self.item?.tag
    }
    
    public init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = .white
        self.maskNode = ASImageNode()
        self.maskNode.isUserInteractionEnabled = false
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomTopStripeNode = ASDisplayNode()
        self.bottomTopStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleValueNode = TextNode()
        self.titleValueNode.isUserInteractionEnabled = false
        self.expandArrowNode = ASImageNode()
        self.expandArrowNode.displaysAsynchronously = false
        self.highlightedBackgroundNode = ASDisplayNode()
        self.highlightedBackgroundNode.isLayerBacked = true
        self.activateArea = AccessibilityAreaNode()
        self.subItemContainer = ASDisplayNode()
        self.subItemContainer.clipsToBounds = true
        super.init(layerBacked: false)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.titleValueNode)
        self.addSubnode(self.expandArrowNode)
        self.addSubnode(self.activateArea)
        self.addSubnode(self.subItemContainer)
        self.activateArea.activate = { [weak self] in
            guard let strongSelf = self, let item = strongSelf.item else {
                return false
            }
            item.toggleExpanded()
            return true
        }
    }
    
    public func asyncLayout() -> (_ item: ItemListExpandableSelectionItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeTitleValueLayout = TextNode.asyncLayout(self.titleValueNode)
        let currentItem = self.item
        return { item, params, neighbors in
            let separatorHeight = UIScreenPixel
            let titleFont = Font.regular(item.presentationData.fontSize.itemListBaseFontSize)
            var updatedTheme: PresentationTheme?
            if currentItem?.presentationData.theme !== item.presentationData.theme {
                updatedTheme = item.presentationData.theme
            }
            let itemBackgroundColor: UIColor
            let itemSeparatorColor: UIColor
            let separatorRightInset: CGFloat = item.systemStyle == .glass ? 16.0 : 0.0
            var contentSize: CGSize
            var insets: UIEdgeInsets
            switch item.style {
            case .plain:
                itemBackgroundColor = item.presentationData.theme.list.plainBackgroundColor
                itemSeparatorColor = item.presentationData.theme.list.itemPlainSeparatorColor
                contentSize = CGSize(width: params.width, height: item.systemStyle == .glass ? 52.0 : 44.0)
                insets = itemListNeighborsPlainInsets(neighbors)
            case .blocks:
                itemBackgroundColor = item.presentationData.theme.list.itemBlocksBackgroundColor
                itemSeparatorColor = item.presentationData.theme.list.itemBlocksSeparatorColor
                contentSize = CGSize(width: params.width, height: item.systemStyle == .glass ? 52.0 : 44.0)
                insets = itemListNeighborsGroupedInsets(neighbors, params)
            }
            let leftInset: CGFloat = 16.0 + params.leftInset
            let selectedCount = item.options.filter(\.isSelected).count
            let titleValue: String
            switch item.mode {
            case .single:
                titleValue = item.options.first(where: { $0.isSelected })?.title ?? "\(selectedCount)/\(item.options.count)"
            case .multiple:
                titleValue = "\(selectedCount)/\(item.options.count)"
            }
            let arrowReservedWidth: CGFloat = 30.0
            let valueRightInset = params.rightInset + 16.0 + arrowReservedWidth
            let titleConstrainedWidth = params.width - leftInset - valueRightInset - 12.0
            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.title, font: titleFont, textColor: item.presentationData.theme.list.itemPrimaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: titleConstrainedWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            let valueConstrainedWidth = max(40.0, params.width - leftInset - valueRightInset - titleLayout.size.width - 12.0)
            let (titleValueLayout, titleValueApply) = makeTitleValueLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: titleValue, font: Font.regular(16.0), textColor: item.presentationData.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: valueConstrainedWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            let verticalInset: CGFloat = item.systemStyle == .glass ? 15.0 : 11.0
            contentSize.height = max(contentSize.height, titleLayout.size.height + verticalInset * 2.0)
            let mainContentHeight = contentSize.height
            let optionHeight: CGFloat = item.systemStyle == .glass ? 52.0 : 44.0
            let effectiveSubItemsHeight: CGFloat = item.isExpanded ? CGFloat(item.options.count) * optionHeight : 0.0
            contentSize.height += effectiveSubItemsHeight
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            return (layout, { [weak self] animation in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item
                let transition: ContainedViewLayoutTransition = animation.transition
                strongSelf.activateArea.frame = CGRect(origin: CGPoint(x: params.leftInset, y: 0.0), size: CGSize(width: params.width - params.leftInset - params.rightInset, height: mainContentHeight))
                strongSelf.activateArea.accessibilityLabel = item.title
                strongSelf.activateArea.accessibilityValue = titleValue
                if updatedTheme != nil {
                    strongSelf.topStripeNode.backgroundColor = itemSeparatorColor
                    strongSelf.bottomTopStripeNode.backgroundColor = itemSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = itemSeparatorColor
                    strongSelf.backgroundNode.backgroundColor = itemBackgroundColor
                    strongSelf.highlightedBackgroundNode.backgroundColor = item.presentationData.theme.list.itemHighlightedBackgroundColor
                    strongSelf.expandArrowNode.image = generateTintedImage(image: UIImage(bundleImageName: "Item List/DisclosureArrow"), color: item.presentationData.theme.list.itemPrimaryTextColor)
                }
                switch item.style {
                case .plain:
                    if strongSelf.backgroundNode.supernode != nil {
                        strongSelf.backgroundNode.removeFromSupernode()
                    }
                    if strongSelf.topStripeNode.supernode != nil {
                        strongSelf.topStripeNode.removeFromSupernode()
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 0)
                    }
                    if strongSelf.bottomTopStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomTopStripeNode, at: 1)
                    }
                    if strongSelf.maskNode.supernode != nil {
                        strongSelf.maskNode.removeFromSupernode()
                    }
                    strongSelf.bottomTopStripeNode.frame = CGRect(origin: CGPoint(x: leftInset, y: mainContentHeight - separatorHeight), size: CGSize(width: params.width - leftInset, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: leftInset, y: layout.contentSize.height - separatorHeight), size: CGSize(width: params.width - leftInset, height: separatorHeight))
                case .blocks:
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    if strongSelf.bottomTopStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomTopStripeNode, at: 3)
                    }
                    if strongSelf.maskNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.maskNode, aboveSubnode: strongSelf.activateArea)
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
                    switch neighbors.bottom {
                    case .sameSection(false):
                        bottomStripeInset = leftInset
                        strongSelf.bottomStripeNode.isHidden = false
                        strongSelf.bottomTopStripeNode.isHidden = false
                    default:
                        bottomStripeInset = 0.0
                        hasBottomCorners = true
                        strongSelf.bottomStripeNode.isHidden = hasCorners
                        strongSelf.bottomTopStripeNode.isHidden = false
                    }
                    strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.presentationData.theme, top: hasTopCorners, bottom: hasBottomCorners, glass: item.systemStyle == .glass) : nil
                    let backgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    animation.animator.updateFrame(layer: strongSelf.backgroundNode.layer, frame: backgroundFrame, completion: nil)
                    animation.animator.updateFrame(layer: strongSelf.maskNode.layer, frame: backgroundFrame.insetBy(dx: params.leftInset, dy: 0.0), completion: nil)
                    animation.animator.updateFrame(layer: strongSelf.topStripeNode.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight)), completion: nil)
                    animation.animator.updateFrame(layer: strongSelf.bottomTopStripeNode.layer, frame: CGRect(origin: CGPoint(x: bottomStripeInset, y: mainContentHeight - separatorHeight), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight)), completion: nil)
                    animation.animator.updateFrame(layer: strongSelf.bottomStripeNode.layer, frame: CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height - separatorHeight), size: CGSize(width: layoutSize.width - bottomStripeInset - params.rightInset - separatorRightInset, height: separatorHeight)), completion: nil)
                }
                let _ = titleApply()
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: leftInset, y: floorToScreenPixels((mainContentHeight - titleLayout.size.height) / 2.0)), size: titleLayout.size)
                let _ = titleValueApply()
                let valueX = params.width - valueRightInset - titleValueLayout.size.width
                strongSelf.titleValueNode.frame = CGRect(origin: CGPoint(x: max(strongSelf.titleNode.frame.maxX + 9.0, valueX), y: strongSelf.titleNode.frame.minY + floor((titleLayout.size.height - titleValueLayout.size.height) / 2.0)), size: titleValueLayout.size)
                if let image = strongSelf.expandArrowNode.image {
                    strongSelf.expandArrowNode.position = CGPoint(x: params.width - params.rightInset - 16.0 - image.size.width * 0.4, y: strongSelf.titleValueNode.frame.midY)
                    let scaleFactor: CGFloat = 0.8
                    strongSelf.expandArrowNode.bounds = CGRect(origin: CGPoint(), size: CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor))
                    transition.updateTransformRotation(node: strongSelf.expandArrowNode, angle: item.isExpanded ? CGFloat.pi * -0.5 : CGFloat.pi * 0.5)
                }
                strongSelf.highlightedBackgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -UIScreenPixel), size: CGSize(width: params.width, height: optionHeight + UIScreenPixel + UIScreenPixel))
                animation.animator.updateFrame(layer: strongSelf.subItemContainer.layer, frame: CGRect(origin: CGPoint(x: 0.0, y: mainContentHeight), size: CGSize(width: params.width, height: effectiveSubItemsHeight)), completion: nil)
                var validIds: [AnyHashable] = []
                let subItemSize = CGSize(width: params.width - params.leftInset - params.rightInset, height: optionHeight)
                var nextSubItemPosition = CGPoint(x: params.leftInset, y: 0.0)
                for option in item.options {
                    validIds.append(option.id)
                    let subItemNode: SelectionOptionNode
                    var subItemNodeTransition = animation.transition
                    if let current = strongSelf.subItemNodes[option.id] {
                        subItemNode = current
                    } else {
                        subItemNodeTransition = .immediate
                        subItemNode = SelectionOptionNode()
                        strongSelf.subItemNodes[option.id] = subItemNode
                        strongSelf.subItemContainer.addSubnode(subItemNode)
                    }
                    let subItemFrame = CGRect(origin: nextSubItemPosition, size: subItemSize)
                    subItemNode.update(presentationData: item.presentationData, option: option, action: { option in
                        item.updated(option)
                        if item.mode == .single {
                            item.toggleExpanded()
                        }
                    }, size: subItemSize, transition: subItemNodeTransition)
                    subItemNodeTransition.updateFrame(node: subItemNode, frame: subItemFrame)
                    nextSubItemPosition.y += subItemSize.height
                }
                var removeIds: [AnyHashable] = []
                for (id, itemNode) in strongSelf.subItemNodes {
                    if !validIds.contains(id) {
                        removeIds.append(id)
                        itemNode.removeFromSupernode()
                    }
                }
                for id in removeIds {
                    strongSelf.subItemNodes.removeValue(forKey: id)
                }
            })
        }
    }
    
    override public func accessibilityActivate() -> Bool {
        return false
    }
    
    override public func visibleForSelection(at point: CGPoint) -> Bool {
        if !self.canBeSelected {
            return false
        }
        if point.y > self.subItemContainer.frame.minY {
            return false
        }
        return true
    }
    
    override public func setHighlighted(_ highlighted: Bool, at point: CGPoint, animated: Bool) {
        var highlighted = highlighted
        if point.y > self.subItemContainer.frame.minY {
            highlighted = false
        }
        super.setHighlighted(highlighted, at: point, animated: animated)
        if highlighted {
            self.highlightedBackgroundNode.alpha = 1.0
            if self.highlightedBackgroundNode.supernode == nil {
                var anchorNode: ASDisplayNode?
                if self.bottomStripeNode.supernode != nil {
                    anchorNode = self.bottomStripeNode
                } else if self.topStripeNode.supernode != nil {
                    anchorNode = self.topStripeNode
                } else if self.backgroundNode.supernode != nil {
                    anchorNode = self.backgroundNode
                }
                if let anchorNode = anchorNode {
                    self.insertSubnode(self.highlightedBackgroundNode, aboveSubnode: anchorNode)
                } else {
                    self.addSubnode(self.highlightedBackgroundNode)
                }
            }
        } else {
            if self.highlightedBackgroundNode.supernode != nil {
                if animated {
                    self.highlightedBackgroundNode.layer.animateAlpha(from: self.highlightedBackgroundNode.alpha, to: 0.0, duration: 0.4, completion: { [weak self] completed in
                        if let strongSelf = self, completed {
                            strongSelf.highlightedBackgroundNode.removeFromSupernode()
                        }
                    })
                    self.highlightedBackgroundNode.alpha = 0.0
                } else {
                    self.highlightedBackgroundNode.removeFromSupernode()
                }
            }
        }
    }
    
    override public func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.allowsGroupOpacity = true
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4, completion: { [weak self] _ in
            self?.layer.allowsGroupOpacity = false
        })
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.allowsGroupOpacity = true
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
