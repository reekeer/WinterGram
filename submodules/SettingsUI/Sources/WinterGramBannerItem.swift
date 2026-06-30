import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils

private func winterGramBannerIcon(size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { rendererContext in
        let context = rendererContext.cgContext
        let bounds = CGRect(origin: .zero, size: size)
        context.saveGState()
        UIBezierPath(roundedRect: bounds, cornerRadius: size.height * 0.225).addClip()
        let colors = [UIColor(rgb: 0x5CC0F5).cgColor, UIColor(rgb: 0x2D7FD6).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: [])
        }
        context.restoreGState()
        if let glyph = UIImage(systemName: "snowflake", withConfiguration: UIImage.SymbolConfiguration(pointSize: size.height * 0.56, weight: .semibold))?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            let glyphSize = glyph.size
            glyph.draw(in: CGRect(x: floor((size.width - glyphSize.width) / 2.0), y: floor((size.height - glyphSize.height) / 2.0), width: glyphSize.width, height: glyphSize.height))
        }
    }
}

private func winterGramBannerRoundedIcon(image: UIImage, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        let bounds = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: bounds, cornerRadius: size.height * 0.225).addClip()
        image.draw(in: bounds)
    }
}

class WinterGramBannerItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let title: String
    let subtitle: String
    let iconImage: UIImage?
    let sectionId: ItemListSectionId
    let isAlwaysPlain: Bool = true

    init(theme: PresentationTheme, title: String, subtitle: String, iconImage: UIImage? = nil, sectionId: ItemListSectionId) {
        self.theme = theme
        self.title = title
        self.subtitle = subtitle
        self.iconImage = iconImage
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            Queue.mainQueue().async {
                let node = WinterGramBannerItemNode()
                let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                node.contentSize = layout.contentSize
                node.insets = layout.insets
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? WinterGramBannerItemNode {
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

class WinterGramBannerItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let iconNode: ASImageNode
    private let titleNode: ImmediateTextNode
    private let subtitleNode: ImmediateTextNode

    private var item: WinterGramBannerItem?

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.isUserInteractionEnabled = false
        self.titleNode = ImmediateTextNode()
        self.titleNode.displaysAsynchronously = false
        self.titleNode.textAlignment = .center
        self.subtitleNode = ImmediateTextNode()
        self.subtitleNode.displaysAsynchronously = false
        self.subtitleNode.textAlignment = .center
        self.subtitleNode.maximumNumberOfLines = 2

        super.init(layerBacked: false)

        self.insertSubnode(self.backgroundNode, at: 0)
        self.addSubnode(self.iconNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
    }

    func asyncLayout() -> (_ item: WinterGramBannerItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, _ in
            let hasSubtitle = !item.subtitle.isEmpty
            let iconSize = CGSize(width: hasSubtitle ? 96.0 : 80.0, height: hasSubtitle ? 96.0 : 80.0)
            let topInset: CGFloat = hasSubtitle ? 14.0 : 10.0
            let iconTitleSpacing: CGFloat = hasSubtitle ? 10.0 : 8.0
            let titleSubtitleSpacing: CGFloat = 4.0

            let titleFont = Font.semibold(hasSubtitle ? 26.0 : 22.0)
            let subtitleFont = Font.regular(14.0)
            let constrainedWidth = params.width - params.leftInset - params.rightInset - 40.0

            let contentHeight: CGFloat = hasSubtitle ? 196.0 : 142.0
            let layout = ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: contentHeight), insets: UIEdgeInsets())

            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item
                let width = params.width

                strongSelf.backgroundNode.backgroundColor = .clear
                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: width, height: contentHeight))

                if let iconImage = item.iconImage {
                    strongSelf.iconNode.image = winterGramBannerRoundedIcon(image: iconImage, size: iconSize)
                } else {
                    strongSelf.iconNode.image = winterGramBannerIcon(size: iconSize)
                }

                strongSelf.titleNode.attributedText = NSAttributedString(string: item.title, font: titleFont, textColor: item.theme.list.itemPrimaryTextColor)
                let titleSize = strongSelf.titleNode.updateLayout(CGSize(width: constrainedWidth, height: 30.0))

                var subtitleSize = CGSize()
                if hasSubtitle {
                    strongSelf.subtitleNode.attributedText = NSAttributedString(string: item.subtitle, font: subtitleFont, textColor: item.theme.list.itemSecondaryTextColor)
                    subtitleSize = strongSelf.subtitleNode.updateLayout(CGSize(width: constrainedWidth, height: 40.0))
                } else {
                    strongSelf.subtitleNode.attributedText = nil
                }

                strongSelf.iconNode.frame = CGRect(origin: CGPoint(x: floor((width - iconSize.width) / 2.0), y: topInset), size: iconSize)
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: floor((width - titleSize.width) / 2.0), y: topInset + iconSize.height + iconTitleSpacing), size: titleSize)
                strongSelf.subtitleNode.frame = CGRect(origin: CGPoint(x: floor((width - subtitleSize.width) / 2.0), y: topInset + iconSize.height + iconTitleSpacing + titleSize.height + titleSubtitleSpacing), size: subtitleSize)
            })
        }
    }
}
