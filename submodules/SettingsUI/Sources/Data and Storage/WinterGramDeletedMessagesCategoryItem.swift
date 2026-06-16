import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import CheckNode

// WinterGram: a Storage-Usage-style category row for the deleted-messages screen.
// Shows a colored check-circle, title + percentage, and the size on the right.
final class WinterGramDeletedMessagesCategoryItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let category: WinterGramDeletedMessageCategory
    let color: UIColor
    let title: String
    let size: Int64
    let fraction: Double
    let checked: Bool
    let isLast: Bool
    let sectionId: ItemListSectionId
    let toggle: () -> Void
    
    init(presentationData: ItemListPresentationData, category: WinterGramDeletedMessageCategory, color: UIColor, title: String, size: Int64, fraction: Double, checked: Bool, isLast: Bool, sectionId: ItemListSectionId, toggle: @escaping () -> Void) {
        self.presentationData = presentationData
        self.category = category
        self.color = color
        self.title = title
        self.size = size
        self.fraction = fraction
        self.checked = checked
        self.isLast = isLast
        self.sectionId = sectionId
        self.toggle = toggle
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = WinterGramDeletedMessagesCategoryItemNode()
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
            if let nodeValue = node() as? WinterGramDeletedMessagesCategoryItemNode {
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

final class WinterGramDeletedMessagesCategoryItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let checkNode: CheckNode
    private let titleNode: ImmediateTextNode
    private let percentNode: ImmediateTextNode
    private let sizeNode: ImmediateTextNode
    private var separatorNode: ASDisplayNode?
    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var tapAction: (() -> Void)?
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        self.maskNode = ASImageNode()
        
        self.checkNode = CheckNode(theme: CheckNodeTheme(backgroundColor: .gray, strokeColor: .white, borderColor: .gray, overlayBorder: false, hasInset: false, hasShadow: false), content: .check(isRectangle: false))
        self.titleNode = ImmediateTextNode()
        self.titleNode.displaysAsynchronously = false
        self.titleNode.isUserInteractionEnabled = false
        self.percentNode = ImmediateTextNode()
        self.percentNode.displaysAsynchronously = false
        self.percentNode.isUserInteractionEnabled = false
        self.sizeNode = ImmediateTextNode()
        self.sizeNode.displaysAsynchronously = false
        self.sizeNode.isUserInteractionEnabled = false
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.checkNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.percentNode)
        self.addSubnode(self.sizeNode)
    }
    
    override func didLoad() {
        super.didLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapPressed))
        self.tapGestureRecognizer = tap
        self.view.addGestureRecognizer(tap)
    }
    
    @objc private func tapPressed() {
        self.tapAction?()
    }
    
    func asyncLayout() -> (_ item: WinterGramDeletedMessagesCategoryItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let height: CGFloat = 52.0
            let contentSize = CGSize(width: params.width, height: height)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let separatorHeight = UIScreenPixel
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            let theme = item.presentationData.theme
            
            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.tapAction = item.toggle
                
                strongSelf.backgroundNode.backgroundColor = theme.list.itemBlocksBackgroundColor
                strongSelf.topStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor
                strongSelf.bottomStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor
                
                if strongSelf.backgroundNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                }
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
                switch neighbors.top {
                case .sameSection(false):
                    strongSelf.topStripeNode.isHidden = true
                default:
                    strongSelf.topStripeNode.isHidden = hasCorners
                }
                let bottomStripeInset: CGFloat
                let bottomStripeOffset: CGFloat
                switch neighbors.bottom {
                case .sameSection(false):
                    bottomStripeInset = params.leftInset + 16.0
                    bottomStripeOffset = 0.0
                default:
                    bottomStripeInset = 0.0
                    bottomStripeOffset = separatorHeight
                }
                
                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layoutSize.width, height: contentSize.height))
                strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                
                strongSelf.maskNode.image = nil
                if hasCorners {
                    let maskingCornerRadius: CGFloat = 10.0
                    if let cornersImage = generateStretchableFilledCircleImage(radius: maskingCornerRadius, color: .black) {
                        strongSelf.maskNode.image = cornersImage
                    }
                }
                
                let checkDiameter: CGFloat = 22.0
                let checkFrame = CGRect(origin: CGPoint(x: 20.0, y: floor((height - checkDiameter) / 2.0)), size: CGSize(width: checkDiameter, height: checkDiameter))
                strongSelf.checkNode.frame = checkFrame
                strongSelf.checkNode.theme = CheckNodeTheme(
                    backgroundColor: item.color,
                    strokeColor: theme.list.itemCheckColors.foregroundColor,
                    borderColor: theme.list.itemCheckColors.strokeColor,
                    overlayBorder: false,
                    hasInset: false,
                    hasShadow: false
                )
                strongSelf.checkNode.setSelected(item.checked, animated: false)
                
                let sizeFormatting = DataSizeStringFormatting(strings: item.presentationData.strings, decimalSeparator: item.presentationData.dateTimeFormat.decimalSeparator)
                let sizeString = dataSizeString(item.size, formatting: sizeFormatting)
                strongSelf.sizeNode.attributedText = NSAttributedString(string: sizeString, font: Font.regular(17.0), textColor: theme.list.itemSecondaryTextColor)
                let sizeSize = strongSelf.sizeNode.updateLayout(CGSize(width: params.width - 100.0, height: 44.0))
                
                let percentString: String
                if item.fraction > 0.0 {
                    let value = floor(item.fraction * 100.0 * 10.0) / 10.0
                    if value < 0.1 {
                        percentString = "<0.1%"
                    } else if abs(Double(Int(value)) - value) < 0.001 {
                        percentString = "\(Int(value))%"
                    } else {
                        percentString = "\(value)%"
                    }
                } else {
                    percentString = ""
                }
                strongSelf.percentNode.attributedText = NSAttributedString(string: percentString, font: Font.regular(17.0), textColor: theme.list.itemSecondaryTextColor)
                let percentSize = strongSelf.percentNode.updateLayout(CGSize(width: params.width - 100.0, height: 44.0))
                
                strongSelf.titleNode.attributedText = NSAttributedString(string: item.title, font: Font.regular(17.0), textColor: theme.list.itemPrimaryTextColor)
                
                let sizeFrame = CGRect(origin: CGPoint(x: params.width - 16.0 - sizeSize.width, y: floor((height - sizeSize.height) / 2.0)), size: sizeSize)
                let percentFrame = CGRect(origin: CGPoint(x: sizeFrame.minX - 8.0 - percentSize.width, y: floor((height - percentSize.height) / 2.0)), size: percentSize)
                let titleMaxWidth = max(0.0, percentFrame.minX - 8.0 - 62.0)
                let titleSize = strongSelf.titleNode.updateLayout(CGSize(width: titleMaxWidth, height: 44.0))
                let titleFrame = CGRect(origin: CGPoint(x: 62.0, y: floor((height - titleSize.height) / 2.0)), size: titleSize)
                
                strongSelf.titleNode.frame = titleFrame
                strongSelf.percentNode.frame = percentFrame
                strongSelf.sizeNode.frame = sizeFrame
                
                if item.isLast {
                    if let separatorNode = strongSelf.separatorNode {
                        separatorNode.isHidden = true
                    }
                } else {
                    let separatorNode: ASDisplayNode
                    if let current = strongSelf.separatorNode {
                        separatorNode = current
                    } else {
                        separatorNode = ASDisplayNode()
                        separatorNode.isLayerBacked = true
                        strongSelf.separatorNode = separatorNode
                        strongSelf.insertSubnode(separatorNode, aboveSubnode: strongSelf.backgroundNode)
                    }
                    separatorNode.isHidden = false
                    separatorNode.backgroundColor = theme.list.itemBlocksSeparatorColor
                    separatorNode.frame = CGRect(origin: CGPoint(x: 62.0, y: height), size: CGSize(width: params.width - 62.0, height: UIScreenPixel))
                }
            })
        }
    }
}

// Expose a factory so the controller can use the custom row without knowing the private types.
func winterGramDeletedMessagesCategoryItem(
    presentationData: ItemListPresentationData,
    category: WinterGramDeletedMessageCategory,
    color: UIColor,
    title: String,
    size: Int64,
    fraction: Double,
    checked: Bool,
    isLast: Bool,
    sectionId: ItemListSectionId,
    toggle: @escaping () -> Void
) -> ListViewItem {
    return WinterGramDeletedMessagesCategoryItem(
        presentationData: presentationData,
        category: category,
        color: color,
        title: title,
        size: size,
        fraction: fraction,
        checked: checked,
        isLast: isLast,
        sectionId: sectionId,
        toggle: toggle
    )
}
