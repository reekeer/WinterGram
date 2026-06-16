import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import ItemListPeerActionItem
import ItemListPeerItem
import AccountContext
import TelegramStringFormatting
import UndoUI
import ComponentFlow
import StorageUsageScreen

private func generatePieChartImage(size: CGSize, values: [(color: UIColor, fraction: CGFloat)], theme: PresentationTheme) -> UIImage? {
    return generateImage(size, contextGenerator: { targetSize, context in
        context.clear(CGRect(origin: .zero, size: targetSize))
        let center = CGPoint(x: targetSize.width / 2.0, y: targetSize.height / 2.0)
        let outerRadius = min(targetSize.width, targetSize.height) / 2.0 - 2.0
        let innerRadius = outerRadius * 0.52
        let separatorAngle: CGFloat = 0.03
        var startAngle: CGFloat = -CGFloat.pi / 2.0
        let total = values.reduce(0.0) { $0 + max(0.0, $1.fraction) }
        guard total > 0.0 else {
            let emptyColor = theme.list.itemAccentColor.withAlphaComponent(0.25)
            context.setFillColor(emptyColor.cgColor)
            context.fillEllipse(in: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2.0, height: outerRadius * 2.0))
            context.setFillColor(theme.list.blocksBackgroundColor.cgColor)
            context.fillEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2.0, height: innerRadius * 2.0))
            return
        }
        for (color, fraction) in values {
            let rawSweep = (fraction / total) * CGFloat.pi * 2.0
            let sweep = max(0.0, rawSweep - separatorAngle)
            let endAngle = startAngle + sweep
            let path = CGMutablePath()
            path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
            path.closeSubpath()
            context.addPath(path)
            context.setFillColor(color.cgColor)
            context.fillPath()
            startAngle += rawSweep
        }
    }, opaque: false)
}

private let categoryColors: [WinterGramDeletedMessageCategory: UIColor] = [
    .text: UIColor(rgb: 0x34C759),
    .photo: UIColor(rgb: 0x007AFF),
    .video: UIColor(rgb: 0xFF2D55),
    .voice: UIColor(rgb: 0xFF9500),
    .videoMessage: UIColor(rgb: 0xAF52DE),
    .music: UIColor(rgb: 0x5856D6),
    .sticker: UIColor(rgb: 0xFFCC00),
    .other: UIColor(rgb: 0x8E8E93)
]

private func categoryTitle(_ category: WinterGramDeletedMessageCategory, _ strings: PresentationStrings) -> String {
    switch category {
    case .text:
        return strings.WinterGram_DeletedMessages_Text
    case .photo:
        return strings.WinterGram_DeletedMessages_Photos
    case .video:
        return strings.WinterGram_DeletedMessages_Videos
    case .voice:
        return strings.WinterGram_DeletedMessages_Voice
    case .videoMessage:
        return strings.WinterGram_DeletedMessages_VideoMessages
    case .music:
        return strings.WinterGram_DeletedMessages_Music
    case .sticker:
        return strings.WinterGram_DeletedMessages_Stickers
    case .other:
        return strings.WinterGram_DeletedMessages_Other
    }
}

private final class WinterGramDeletedMessagesChartItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let chartData: PieChartComponent.ChartData
    let totalText: String
    let sectionId: ItemListSectionId

    init(presentationData: ItemListPresentationData, chartData: PieChartComponent.ChartData, totalText: String, sectionId: ItemListSectionId) {
        self.presentationData = presentationData
        self.chartData = chartData
        self.totalText = totalText
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = WinterGramDeletedMessagesChartItemNode()
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
            if let nodeValue = node() as? WinterGramDeletedMessagesChartItemNode {
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

private final class WinterGramDeletedMessagesChartItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let chartHost: ComponentHostView<Empty>
    private let totalLabelNode: ImmediateTextNode

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        self.maskNode = ASImageNode()
        self.chartHost = ComponentHostView<Empty>()
        self.totalLabelNode = ImmediateTextNode()
        self.totalLabelNode.displaysAsynchronously = false
        self.totalLabelNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)

        self.addSubnode(self.totalLabelNode)
    }

    func asyncLayout() -> (_ item: WinterGramDeletedMessagesChartItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let imageSize = CGSize(width: 240.0, height: 240.0)
            let contentSize = CGSize(width: params.width, height: imageSize.height + 24.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let separatorHeight = UIScreenPixel
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size

            let theme = item.presentationData.theme

            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }

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

                if strongSelf.chartHost.superview == nil {
                    strongSelf.view.addSubview(strongSelf.chartHost)
                }
                // Keep the centre total label above the pie.
                strongSelf.view.bringSubviewToFront(strongSelf.totalLabelNode.view)
                let chartSize = strongSelf.chartHost.update(
                    transition: .immediate,
                    component: AnyComponent(PieChartComponent(
                        theme: theme,
                        strings: item.presentationData.strings,
                        emptyColor: theme.list.itemAccentColor.withAlphaComponent(0.25),
                        chartData: item.chartData
                    )),
                    environment: {},
                    containerSize: imageSize
                )
                let chartFrame = CGRect(origin: CGPoint(x: floor((params.width - chartSize.width) / 2.0), y: 12.0), size: chartSize)
                strongSelf.chartHost.frame = chartFrame

                // Total size in the donut centre, matching the native Storage Usage screen.
                strongSelf.totalLabelNode.attributedText = NSAttributedString(string: item.totalText, font: Font.semibold(20.0), textColor: theme.list.itemPrimaryTextColor)
                let totalLabelSize = strongSelf.totalLabelNode.updateLayout(CGSize(width: chartFrame.width, height: 44.0))
                strongSelf.totalLabelNode.frame = CGRect(origin: CGPoint(x: chartFrame.minX + floor((chartFrame.width - totalLabelSize.width) / 2.0), y: chartFrame.minY + floor((chartFrame.height - totalLabelSize.height) / 2.0)), size: totalLabelSize)
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

private enum WinterGramDeletedMessagesControllerSection: Int32 {
    case overview
    case chart
    case categories
    case topChats
    case delete
}

private enum WinterGramDeletedMessagesControllerEntry: ItemListNodeEntry {
    case overviewHeader(PresentationTheme, String)
    case overviewInfo(PresentationTheme, String)
    case chart(PresentationTheme, PieChartComponent.ChartData, String)
    case categoryHeader(PresentationTheme, String)
    case category(PresentationTheme, WinterGramDeletedMessageCategory, Int64, Int, Bool, Bool, Double)
    case topChatsHeader(PresentationTheme, String)
    case topChat(PresentationTheme, EnginePeer, Int, Int64, Int32)
    case delete(PresentationTheme, String, Bool)
    
    var section: ItemListSectionId {
        switch self {
        case .overviewHeader, .overviewInfo:
            return WinterGramDeletedMessagesControllerSection.overview.rawValue
        case .chart:
            return WinterGramDeletedMessagesControllerSection.chart.rawValue
        case .categoryHeader, .category:
            return WinterGramDeletedMessagesControllerSection.categories.rawValue
        case .topChatsHeader, .topChat:
            return WinterGramDeletedMessagesControllerSection.topChats.rawValue
        case .delete:
            return WinterGramDeletedMessagesControllerSection.delete.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .overviewHeader:
            return 0
        case .overviewInfo:
            return 1
        case .chart:
            return 2
        case .categoryHeader:
            return 3
        case let .category(_, category, _, _, _, _, _):
            return 10 + category.rawValue
        case .topChatsHeader:
            return 200
        case let .topChat(_, _, _, _, index):
            return 210 + index
        case .delete:
            return 1000
        }
    }
    
    static func ==(lhs: WinterGramDeletedMessagesControllerEntry, rhs: WinterGramDeletedMessagesControllerEntry) -> Bool {
        switch lhs {
        case let .overviewHeader(lhsTheme, lhsText):
            if case let .overviewHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .overviewInfo(lhsTheme, lhsText):
            if case let .overviewInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .chart(lhsTheme, lhsData, lhsTotal):
            if case let .chart(rhsTheme, rhsData, rhsTotal) = rhs, lhsTheme === rhsTheme, lhsData == rhsData, lhsTotal == rhsTotal {
                return true
            } else {
                return false
            }
        case let .categoryHeader(lhsTheme, lhsText):
            if case let .categoryHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .category(lhsTheme, lhsCategory, lhsSize, lhsCount, lhsChecked, lhsIsLast, lhsFraction):
            if case let .category(rhsTheme, rhsCategory, rhsSize, rhsCount, rhsChecked, rhsIsLast, rhsFraction) = rhs, lhsTheme === rhsTheme, lhsCategory == rhsCategory, lhsSize == rhsSize, lhsCount == rhsCount, lhsChecked == rhsChecked, lhsIsLast == rhsIsLast, lhsFraction == rhsFraction {
                return true
            } else {
                return false
            }
        case let .topChatsHeader(lhsTheme, lhsText):
            if case let .topChatsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .topChat(lhsTheme, lhsPeer, lhsCount, lhsSize, lhsIndex):
            if case let .topChat(rhsTheme, rhsPeer, rhsCount, rhsSize, rhsIndex) = rhs, lhsTheme === rhsTheme, lhsPeer == rhsPeer, lhsCount == rhsCount, lhsSize == rhsSize, lhsIndex == rhsIndex {
                return true
            } else {
                return false
            }
        case let .delete(lhsTheme, lhsText, lhsEnabled):
            if case let .delete(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: WinterGramDeletedMessagesControllerEntry, rhs: WinterGramDeletedMessagesControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramDeletedMessagesControllerArguments
        switch self {
        case let .overviewHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .overviewInfo(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
        case let .chart(_, chartData, totalText):
            return WinterGramDeletedMessagesChartItem(presentationData: presentationData, chartData: chartData, totalText: totalText, sectionId: self.section)
        case let .categoryHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .category(_, category, size, _, checked, isLast, fraction):
            let title = categoryTitle(category, presentationData.strings)
            return winterGramDeletedMessagesCategoryItem(
                presentationData: presentationData,
                category: category,
                color: categoryColors[category] ?? presentationData.theme.list.itemAccentColor,
                title: title,
                size: size,
                fraction: fraction,
                checked: checked,
                isLast: isLast,
                sectionId: self.section,
                toggle: {
                    arguments.toggleCategory(category)
                }
            )
        case let .topChatsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .topChat(_, peer, count, size, _):
            let sizeFormatting = DataSizeStringFormatting(strings: presentationData.strings, decimalSeparator: presentationData.dateTimeFormat.decimalSeparator)
            let subtitle = "\(count) • \(dataSizeString(size, formatting: sizeFormatting))"
            return ItemListPeerItem(presentationData: presentationData, dateTimeFormat: presentationData.dateTimeFormat, nameDisplayOrder: presentationData.nameDisplayOrder, context: arguments.context, peer: peer, presence: nil, text: .text(subtitle, .secondary), label: .none, editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: nil), switchValue: nil, enabled: true, selectable: false, sectionId: self.section, action: nil, setPeerIdWithRevealedOptions: { _, _ in }, removePeer: { _ in })
        case let .delete(_, text, enabled):
            return ItemListPeerActionItem(presentationData: presentationData, style: .blocks, icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme), title: text, sectionId: self.section, color: enabled ? .destructive : .disabled, editing: false, action: enabled ? {
                arguments.deleteSelected()
            } : nil)
        }
    }
}

private func generateFilledCircleImage(diameter: CGFloat, color: UIColor) -> UIImage? {
    return generateImage(CGSize(width: diameter, height: diameter), contextGenerator: { size, context in
        context.clear(CGRect(origin: .zero, size: size))
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
    }, opaque: false)
}

private final class WinterGramDeletedMessagesControllerArguments {
    let context: AccountContext
    let toggleCategory: (WinterGramDeletedMessageCategory) -> Void
    let deleteSelected: () -> Void
    
    init(context: AccountContext, toggleCategory: @escaping (WinterGramDeletedMessageCategory) -> Void, deleteSelected: @escaping () -> Void) {
        self.context = context
        self.toggleCategory = toggleCategory
        self.deleteSelected = deleteSelected
    }
}

private func winterGramDeletedMessagesControllerEntries(stats: WinterGramDeletedMessagesStats, topPeers: [EnginePeer], selectedCategories: Set<WinterGramDeletedMessageCategory>, strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat, theme: PresentationTheme) -> [WinterGramDeletedMessagesControllerEntry] {
    let sizeFormatting = DataSizeStringFormatting(strings: strings, decimalSeparator: dateTimeFormat.decimalSeparator)
    
    var entries: [WinterGramDeletedMessagesControllerEntry] = []
    
    entries.append(.overviewHeader(theme, strings.WinterGram_DeletedMessages_Title.uppercased()))
    entries.append(.overviewInfo(theme, "\(strings.WinterGram_DeletedMessages_Total): \(stats.totalCount) • \(dataSizeString(stats.totalSize, formatting: sizeFormatting))"))
    
    let chartTotal = stats.categories.reduce(Int64(0)) { $0 + max(0, $1.size) }
    var chartItems: [PieChartComponent.ChartData.Item] = []
    for stat in stats.categories where stat.size > 0 {
        let color = categoryColors[stat.category] ?? theme.list.itemAccentColor
        let fraction = chartTotal > 0 ? Double(stat.size) / Double(chartTotal) : 0.0
        chartItems.append(PieChartComponent.ChartData.Item(
            id: AnyHashable(stat.category),
            displayValue: fraction,
            displaySize: stat.size,
            value: fraction,
            color: color,
            particle: nil,
            title: categoryTitle(stat.category, strings),
            mergeable: false,
            mergeFactor: 1.0
        ))
    }
    let chartTotalText = dataSizeString(chartTotal, formatting: sizeFormatting)
    entries.append(.chart(theme, PieChartComponent.ChartData(items: chartItems), chartTotalText))
    
    entries.append(.categoryHeader(theme, strings.WinterGram_DeletedMessages_SelectTypes.uppercased()))
    let visibleCategories = stats.categories.filter { $0.count > 0 }
    for (index, stat) in visibleCategories.enumerated() {
        let fraction = chartTotal > 0 ? Double(stat.size) / Double(chartTotal) : 0.0
        entries.append(.category(theme, stat.category, stat.size, stat.count, selectedCategories.contains(stat.category), index == visibleCategories.count - 1, fraction))
    }
    
    if !stats.topChats.isEmpty {
        entries.append(.topChatsHeader(theme, strings.WinterGram_DeletedMessages_TopChats.uppercased()))
        var topChatIndex: Int32 = 0
        for stat in stats.topChats {
            if let peer = topPeers.first(where: { $0.id == EnginePeer.Id(stat.peerId) }) {
                entries.append(.topChat(theme, peer, stat.count, stat.size, topChatIndex))
                topChatIndex += 1
            }
        }
    }
    
    let canDelete = !selectedCategories.isEmpty
    entries.append(.delete(theme, strings.WinterGram_DeletedMessages_DeleteSelected, canDelete))
    
    return entries
}

public func winterGramDeletedMessagesController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    
    let selectedCategories = Atomic<Set<WinterGramDeletedMessageCategory>>(value: Set(WinterGramDeletedMessageCategory.allCases))
    let selectedCategoriesPromise = ValuePromise<Set<WinterGramDeletedMessageCategory>>(Set(WinterGramDeletedMessageCategory.allCases), ignoreRepeated: true)
    
    let arguments = WinterGramDeletedMessagesControllerArguments(context: context, toggleCategory: { category in
        let selected = selectedCategories.modify { selected in
            var selected = selected
            if selected.contains(category) {
                selected.remove(category)
            } else {
                selected.insert(category)
            }
            return selected
        }
        selectedCategoriesPromise.set(selected)
    }, deleteSelected: {
        let selected = selectedCategories.with { $0 }
        guard !selected.isEmpty else {
            return
        }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        actionSheet.setItemGroups([ActionSheetItemGroup(items: [
            ActionSheetTextItem(title: presentationData.strings.WinterGram_DeletedMessages_ConfirmDelete),
            ActionSheetButtonItem(title: presentationData.strings.Common_Delete, color: .destructive, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                let _ = (winterGramClearDeletedMessages(postbox: context.account.postbox, categories: selected)
                |> deliverOnMainQueue).start(next: { freedSize in
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let sizeFormatting = DataSizeStringFormatting(strings: presentationData.strings, decimalSeparator: presentationData.dateTimeFormat.decimalSeparator)
                    presentControllerImpl?(UndoOverlayController(presentationData: presentationData, content: .succeed(text: presentationData.strings.WinterGram_DeletedMessages_Deleted(dataSizeString(freedSize, formatting: sizeFormatting)).string, timeout: nil, customUndoText: nil), elevatedLayout: false, action: { _ in return false }), nil)
                    selectedCategoriesPromise.set(Set(WinterGramDeletedMessageCategory.allCases))
                    let _ = selectedCategories.swap(Set(WinterGramDeletedMessageCategory.allCases))
                })
            })
        ]), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
        ])])
        presentControllerImpl?(actionSheet, nil)
    })
    
    let statsSignal = winterGramDeletedMessagesStats(postbox: context.account.postbox)
    let topPeersSignal = statsSignal
    |> map { stats -> [EnginePeer.Id] in
        return stats.topChats.map { EnginePeer.Id($0.peerId) }
    }
    |> distinctUntilChanged
    |> mapToSignal { peerIds -> Signal<[EnginePeer], NoError> in
        guard !peerIds.isEmpty else {
            return .single([])
        }
        return context.engine.data.subscribe(
            EngineDataMap(peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:)))
        )
        |> map { peerMap -> [EnginePeer] in
            return peerMap.values.compactMap { $0 }
        }
    }
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statsSignal,
        selectedCategoriesPromise.get(),
        topPeersSignal
    )
    |> map { presentationData, stats, selectedCategories, topPeers -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.WinterGram_DeletedMessages_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: winterGramDeletedMessagesControllerEntries(stats: stats, topPeers: topPeers, selectedCategories: selectedCategories, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat, theme: presentationData.theme), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    
    return controller
}
