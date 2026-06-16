import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ComponentFlow
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramPresentationData
import GiftItemComponent

// WinterGram: a simple grid picker of all regular (generic) star gifts — including sold-out ones still
// present in the cached catalog — used to add a NON-unique gift "visually" to the profile.
public final class WinterGramGiftPickerScreen: ViewController {
    private final class Node: ViewControllerTracingNode {
        private weak var controller: WinterGramGiftPickerScreen?
        private let context: AccountContext
        private var presentationData: PresentationData

        private let scrollNode: ASScrollNode
        private var itemViews: [ComponentHostView<Empty>] = []
        private var gifts: [StarGift] = []
        private var disposable: Disposable?
        private var keepUpdatedDisposable: Disposable?
        private var validLayout: ContainerViewLayout?

        init(controller: WinterGramGiftPickerScreen, context: AccountContext) {
            self.controller = controller
            self.context = context
            self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
            self.scrollNode = ASScrollNode()

            super.init()

            self.backgroundColor = self.presentationData.theme.list.blocksBackgroundColor
            self.scrollNode.view.alwaysBounceVertical = true
            self.addSubnode(self.scrollNode)

            // Make sure the gift catalog is fetched/cached — otherwise the picker would be empty if the
            // user never opened a gift screen before.
            self.keepUpdatedDisposable = context.engine.payments.keepStarGiftsUpdated().startStrict()

            self.disposable = (context.engine.payments.cachedStarGifts()
            |> deliverOnMainQueue).start(next: { [weak self] gifts in
                guard let self else {
                    return
                }
                self.gifts = (gifts ?? []).filter { gift in
                    if case .generic = gift {
                        return true
                    }
                    return false
                }
                if let layout = self.validLayout {
                    self.containerLayoutUpdated(layout: layout, transition: .immediate)
                }
            })
        }

        deinit {
            self.disposable?.dispose()
            self.keepUpdatedDisposable?.dispose()
        }

        func containerLayoutUpdated(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
            self.validLayout = layout

            let topInset = self.controller?.navigationLayout(layout: layout).navigationFrame.maxY ?? ((layout.statusBarHeight ?? 20.0) + 44.0)
            transition.updateFrame(node: self.scrollNode, frame: CGRect(origin: .zero, size: layout.size))

            let columns = 3
            let sideInset = layout.safeInsets.left + 12.0
            let spacing: CGFloat = 10.0
            let availableWidth = layout.size.width - sideInset * 2.0
            let itemWidth = floor((availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns))
            let itemHeight = itemWidth + 34.0

            while self.itemViews.count < self.gifts.count {
                let view = ComponentHostView<Empty>()
                self.scrollNode.view.addSubview(view)
                self.itemViews.append(view)
            }
            while self.itemViews.count > self.gifts.count {
                self.itemViews.removeLast().removeFromSuperview()
            }

            for (index, gift) in self.gifts.enumerated() {
                guard case let .generic(genericGift) = gift else {
                    continue
                }
                let column = index % columns
                let row = index / columns
                let x = sideInset + CGFloat(column) * (itemWidth + spacing)
                let y = topInset + 8.0 + CGFloat(row) * (itemHeight + spacing)

                let view = self.itemViews[index]
                let _ = view.update(
                    transition: .immediate,
                    component: AnyComponent(GiftItemComponent(
                        context: self.context,
                        theme: self.presentationData.theme,
                        strings: self.presentationData.strings,
                        subject: .starGift(gift: genericGift, price: "\(genericGift.price)"),
                        isSoldOut: genericGift.soldOut != nil,
                        action: { [weak self] in
                            self?.controller?.selectGift(gift)
                        }
                    )),
                    environment: {},
                    containerSize: CGSize(width: itemWidth, height: itemHeight)
                )
                view.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: itemWidth, height: itemHeight))
            }

            let rows = self.gifts.isEmpty ? 0 : (self.gifts.count + columns - 1) / columns
            let contentHeight = topInset + 8.0 + CGFloat(rows) * (itemHeight + spacing) + layout.intrinsicInsets.bottom + 16.0
            self.scrollNode.view.contentSize = CGSize(width: layout.size.width, height: max(layout.size.height, contentHeight))
        }
    }

    private let context: AccountContext
    private let completion: (StarGift) -> Void

    public init(context: AccountContext, completion: @escaping (StarGift) -> Void) {
        self.context = context
        self.completion = completion

        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData))

        self.title = presentationData.strings.WinterGram_AddVisualGift
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func cancelPressed() {
        self.dismiss()
    }

    fileprivate func selectGift(_ gift: StarGift) {
        self.completion(gift)
        self.dismiss()
    }

    override public func loadDisplayNode() {
        self.displayNode = Node(controller: self, context: self.context)
        self.displayNodeDidLoad()
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        (self.displayNode as! Node).containerLayoutUpdated(layout: layout, transition: transition)
    }
}
