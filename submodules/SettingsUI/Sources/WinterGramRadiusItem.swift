import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import LegacyComponents
import ItemListUI
import PresentationDataUtils

enum WinterGramRadiusPreviewKind {
    case avatar
    case bubble
}

private func winterGramRadiusPreviewImage(kind: WinterGramRadiusPreviewKind, value: Int32, minValue: Int32, maxValue: Int32, size: CGSize, theme: PresentationTheme, avatarImage: UIImage? = nil) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { rendererContext in
        let context = rendererContext.cgContext
        let bounds = CGRect(origin: .zero, size: size)
        switch kind {
        case .avatar:
            let fraction = max(0.0, min(1.0, CGFloat(value - minValue) / CGFloat(max(1, maxValue - minValue))))
            let cornerRadius = (size.height / 2.0) * fraction
            context.saveGState()
            UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
            if let avatarImage = avatarImage {
                avatarImage.draw(in: bounds)
            } else {
                let colors = [UIColor(rgb: 0x4FB3F0).cgColor, UIColor(rgb: 0x2D7FD6).cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                    context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: [])
                }
                if let glyph = UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: size.height * 0.46, weight: .semibold))?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let glyphSize = glyph.size
                    glyph.draw(in: CGRect(x: floor((size.width - glyphSize.width) / 2.0), y: floor((size.height - glyphSize.height) / 2.0), width: glyphSize.width, height: glyphSize.height))
                }
            }
            context.restoreGState()
        case .bubble:
            let bubbleHeight = size.height * 0.74
            let bubbleRect = CGRect(x: 0.0, y: floor((size.height - bubbleHeight) / 2.0), width: size.width, height: bubbleHeight)
            let cornerRadius = min(CGFloat(max(0, value)), bubbleHeight / 2.0)
            theme.list.itemAccentColor.setFill()
            UIBezierPath(roundedRect: bubbleRect, cornerRadius: cornerRadius).fill()
        }
    }
}

class WinterGramRadiusItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let title: String
    let value: Int32
    let minValue: Int32
    let maxValue: Int32
    let previewKind: WinterGramRadiusPreviewKind
    let avatarSignal: Signal<UIImage?, NoError>?
    let displayValue: (Int32) -> String
    let sectionId: ItemListSectionId
    let valueChanged: ((Int32) -> Void)?
    let updated: (Int32) -> Void

    init(presentationData: ItemListPresentationData, title: String, value: Int32, minValue: Int32, maxValue: Int32, previewKind: WinterGramRadiusPreviewKind, avatarSignal: Signal<UIImage?, NoError>? = nil, displayValue: @escaping (Int32) -> String, sectionId: ItemListSectionId, valueChanged: ((Int32) -> Void)? = nil, updated: @escaping (Int32) -> Void) {
        self.presentationData = presentationData
        self.title = title
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.previewKind = previewKind
        self.avatarSignal = avatarSignal
        self.displayValue = displayValue
        self.sectionId = sectionId
        self.valueChanged = valueChanged
        self.updated = updated
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = WinterGramRadiusItemNode()
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
            if let nodeValue = node() as? WinterGramRadiusItemNode {
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

class WinterGramRadiusItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode

    private let titleNode: ImmediateTextNode
    private let valueNode: ImmediateTextNode
    private let previewNode: ASImageNode
    private var sliderView: TGPhotoEditorSliderView?

    private var item: WinterGramRadiusItem?
    private var layoutParams: ListViewItemLayoutParams?
    private var currentValue: Int32 = 0
    private var currentAvatarImage: UIImage?
    private var avatarDisposable: Disposable?

    private let previewSize = CGSize(width: 48.0, height: 48.0)

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        self.maskNode = ASImageNode()

        self.titleNode = ImmediateTextNode()
        self.titleNode.displaysAsynchronously = false
        self.valueNode = ImmediateTextNode()
        self.valueNode.displaysAsynchronously = false
        self.previewNode = ASImageNode()
        self.previewNode.displaysAsynchronously = false
        self.previewNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)

        self.addSubnode(self.titleNode)
        self.addSubnode(self.valueNode)
    }

    deinit {
        self.avatarDisposable?.dispose()
    }

    private func sliderFrame(params: ListViewItemLayoutParams) -> CGRect {
        let sliderInsetLeft = params.leftInset + 16.0
        let sliderInsetRight = params.width - params.rightInset - 16.0
        return CGRect(origin: CGPoint(x: sliderInsetLeft, y: 42.0), size: CGSize(width: max(0.0, sliderInsetRight - sliderInsetLeft), height: 44.0))
    }

    private func applySliderTheme(_ sliderView: TGPhotoEditorSliderView, theme: PresentationTheme) {
        sliderView.backgroundColor = .clear
        sliderView.backColor = theme.list.itemSecondaryTextColor.withAlphaComponent(0.35)
        sliderView.trackColor = theme.list.itemAccentColor
        sliderView.knobImage = PresentationResourcesItemList.knobImage(theme)
    }

    override func didLoad() {
        super.didLoad()

        let sliderView = TGPhotoEditorSliderView()
        sliderView.enablePanHandling = true
        sliderView.trackCornerRadius = 2.0
        sliderView.lineSize = 4.0
        sliderView.disablesInteractiveTransitionGestureRecognizer = true
        if let item = self.item, let params = self.layoutParams {
            self.applySliderTheme(sliderView, theme: item.presentationData.theme)
            sliderView.minimumValue = CGFloat(item.minValue)
            sliderView.maximumValue = CGFloat(item.maxValue)
            sliderView.startValue = CGFloat(item.minValue)
            sliderView.value = CGFloat(item.value)
            sliderView.frame = self.sliderFrame(params: params)
        }
        self.view.addSubview(sliderView)
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        sliderView.interactionEnded = { [weak self] in
            guard let self, let sliderView = self.sliderView else {
                return
            }
            self.item?.updated(Int32(round(sliderView.value)))
        }
        self.sliderView = sliderView
    }

    func asyncLayout() -> (_ item: WinterGramRadiusItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let contentSize = CGSize(width: params.width, height: 96.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let separatorHeight = UIScreenPixel
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size

            let theme = item.presentationData.theme
            let titleFont = Font.regular(item.presentationData.fontSize.itemListBaseFontSize)
            let valueFont = Font.regular(floor(item.presentationData.fontSize.itemListBaseFontSize * 15.0 / 17.0))

            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item
                strongSelf.layoutParams = params
                strongSelf.currentValue = item.value

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
                    bottomStripeInset = params.leftInset + 16.0
                    bottomStripeOffset = -separatorHeight
                    strongSelf.bottomStripeNode.isHidden = false
                default:
                    bottomStripeInset = 0.0
                    bottomStripeOffset = 0.0
                    hasBottomCorners = true
                    strongSelf.bottomStripeNode.isHidden = hasCorners
                }

                strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(theme, top: hasTopCorners, bottom: hasBottomCorners) : nil

                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.insetBy(dx: params.leftInset, dy: 0.0)
                strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))

                strongSelf.titleNode.attributedText = NSAttributedString(string: item.title, font: titleFont, textColor: theme.list.itemPrimaryTextColor)
                let titleSize = strongSelf.titleNode.updateLayout(CGSize(width: params.width - params.leftInset - params.rightInset - 120.0, height: 30.0))
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 13.0), size: titleSize)

                strongSelf.valueNode.attributedText = NSAttributedString(string: item.displayValue(item.value), font: valueFont, textColor: theme.list.itemSecondaryTextColor)
                let valueSize = strongSelf.valueNode.updateLayout(CGSize(width: 160.0, height: 30.0))
                strongSelf.valueNode.frame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 16.0 - valueSize.width, y: 14.0), size: valueSize)

                strongSelf.previewNode.image = winterGramRadiusPreviewImage(kind: item.previewKind, value: item.value, minValue: item.minValue, maxValue: item.maxValue, size: strongSelf.previewSize, theme: theme, avatarImage: strongSelf.currentAvatarImage)
                strongSelf.previewNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 40.0), size: strongSelf.previewSize)

                if let sliderView = strongSelf.sliderView {
                    strongSelf.applySliderTheme(sliderView, theme: theme)
                    sliderView.minimumValue = CGFloat(item.minValue)
                    sliderView.maximumValue = CGFloat(item.maxValue)
                    sliderView.startValue = CGFloat(item.minValue)
                    if Int32(round(sliderView.value)) != item.value {
                        sliderView.value = CGFloat(item.value)
                    }
                    sliderView.frame = strongSelf.sliderFrame(params: params)
                }

                if let avatarSignal = item.avatarSignal {
                    strongSelf.avatarDisposable?.dispose()
                    strongSelf.avatarDisposable = (avatarSignal
                    |> deliverOnMainQueue).start(next: { [weak strongSelf] image in
                        guard let strongSelf = strongSelf else {
                            return
                        }
                        strongSelf.currentAvatarImage = image
                        if let item = strongSelf.item, let params = strongSelf.layoutParams {
                            strongSelf.previewNode.image = winterGramRadiusPreviewImage(kind: item.previewKind, value: strongSelf.currentValue, minValue: item.minValue, maxValue: item.maxValue, size: strongSelf.previewSize, theme: item.presentationData.theme, avatarImage: image)
                            strongSelf.previewNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 40.0), size: strongSelf.previewSize)
                        }
                    })
                }
            })
        }
    }

    @objc private func sliderValueChanged() {
        guard let sliderView = self.sliderView, let item = self.item, let params = self.layoutParams else {
            return
        }
        let newValue = Int32(round(sliderView.value))
        guard newValue != self.currentValue else {
            return
        }
        self.currentValue = newValue
        item.valueChanged?(newValue)
        let theme = item.presentationData.theme
        let valueFont = Font.regular(floor(item.presentationData.fontSize.itemListBaseFontSize * 15.0 / 17.0))
        self.valueNode.attributedText = NSAttributedString(string: item.displayValue(newValue), font: valueFont, textColor: theme.list.itemSecondaryTextColor)
        let valueSize = self.valueNode.updateLayout(CGSize(width: 160.0, height: 30.0))
        self.valueNode.frame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 16.0 - valueSize.width, y: 14.0), size: valueSize)
        self.previewNode.image = winterGramRadiusPreviewImage(kind: item.previewKind, value: newValue, minValue: item.minValue, maxValue: item.maxValue, size: self.previewSize, theme: theme, avatarImage: self.currentAvatarImage)
    }

    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
