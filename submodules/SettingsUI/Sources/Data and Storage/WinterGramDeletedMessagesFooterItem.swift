import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import SolidRoundedButtonNode

final class WinterGramDeletedMessagesFooterItem: ItemListControllerFooterItem {
    let theme: PresentationTheme
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(theme: PresentationTheme, title: String, isEnabled: Bool, action: @escaping () -> Void) {
        self.theme = theme
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    func isEqual(to: ItemListControllerFooterItem) -> Bool {
        if let item = to as? WinterGramDeletedMessagesFooterItem {
            return self.theme === item.theme && self.title == item.title && self.isEnabled == item.isEnabled
        } else {
            return false
        }
    }

    func node(current: ItemListControllerFooterItemNode?) -> ItemListControllerFooterItemNode {
        if let current = current as? WinterGramDeletedMessagesFooterItemNode {
            current.item = self
            return current
        } else {
            return WinterGramDeletedMessagesFooterItemNode(item: self)
        }
    }
}

final class WinterGramDeletedMessagesFooterItemNode: ItemListControllerFooterItemNode {
    private let backgroundNode: NavigationBackgroundNode
    private let separatorNode: ASDisplayNode
    private let buttonNode: SolidRoundedButtonNode

    private var validLayout: ContainerViewLayout?

    var item: WinterGramDeletedMessagesFooterItem {
        didSet {
            self.updateItem()
            if let layout = self.validLayout {
                let _ = self.updateLayout(layout: layout, transition: .immediate)
            }
        }
    }

    init(item: WinterGramDeletedMessagesFooterItem) {
        self.item = item

        self.backgroundNode = NavigationBackgroundNode(color: item.theme.rootController.tabBar.backgroundColor)
        self.separatorNode = ASDisplayNode()
        self.buttonNode = SolidRoundedButtonNode(theme: SolidRoundedButtonTheme(backgroundColor: .black, foregroundColor: .white), height: 50.0, cornerRadius: 11.0)

        super.init()

        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.separatorNode)
        self.addSubnode(self.buttonNode)

        self.updateItem()
    }

    private func updateItem() {
        self.backgroundNode.updateColor(color: self.item.theme.rootController.tabBar.backgroundColor, transition: .immediate)
        self.separatorNode.backgroundColor = self.item.theme.rootController.tabBar.separatorColor

        let backgroundColor = self.item.theme.list.itemDestructiveColor
        let textColor = self.item.theme.list.itemCheckColors.foregroundColor

        self.buttonNode.updateTheme(SolidRoundedButtonTheme(backgroundColor: backgroundColor, foregroundColor: textColor), animated: false)
        self.buttonNode.title = self.item.title
        self.buttonNode.isUserInteractionEnabled = self.item.isEnabled
        self.buttonNode.alpha = self.item.isEnabled ? 1.0 : 0.5

        self.buttonNode.pressed = { [weak self] in
            self?.item.action()
        }
    }

    override func updateBackgroundAlpha(_ alpha: CGFloat, transition: ContainedViewLayoutTransition) {
        transition.updateAlpha(node: self.backgroundNode, alpha: alpha)
        transition.updateAlpha(node: self.separatorNode, alpha: alpha)
    }

    override func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayout = layout

        let buttonInset: CGFloat = 16.0
        let buttonWidth = layout.size.width - layout.safeInsets.left - layout.safeInsets.right - buttonInset * 2.0
        let buttonHeight = self.buttonNode.updateLayout(width: buttonWidth, transition: transition)
        let topInset: CGFloat = 12.0
        let bottomInset: CGFloat = layout.size.width > 320.0 ? 16.0 : 12.0

        let insets = layout.insets(options: [])
        let panelHeight = buttonHeight + topInset + bottomInset + insets.bottom

        let panelFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - panelHeight), size: CGSize(width: layout.size.width, height: panelHeight))

        transition.updateFrame(node: self.backgroundNode, frame: panelFrame)
        self.backgroundNode.update(size: panelFrame.size, transition: transition)

        transition.updateFrame(node: self.buttonNode, frame: CGRect(origin: CGPoint(x: layout.safeInsets.left + buttonInset, y: panelFrame.minY + topInset), size: CGSize(width: buttonWidth, height: buttonHeight)))

        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: panelFrame.origin, size: CGSize(width: panelFrame.width, height: UIScreenPixel)))

        return panelHeight
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.backgroundNode.frame.contains(point)
    }
}
