import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class WinterGramOnlineTrackerArguments {
    let openHistory: (EnginePeer.Id) -> Void
    let clearAll: () -> Void
    init(openHistory: @escaping (EnginePeer.Id) -> Void, clearAll: @escaping () -> Void) {
        self.openHistory = openHistory
        self.clearAll = clearAll
    }
}

private enum WinterGramOnlineTrackerSection: Int32 {
    case peers
    case actions
}

private enum WinterGramOnlineTrackerEntry: ItemListNodeEntry {
    case peer(index: Int, peerId: EnginePeer.Id, name: String, summary: String)
    case clear
    case footer

    var section: ItemListSectionId {
        switch self {
        case .peer: return WinterGramOnlineTrackerSection.peers.rawValue
        case .clear, .footer: return WinterGramOnlineTrackerSection.actions.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .peer(index, _, _, _): return Int32(index)
        case .clear: return 100000
        case .footer: return 100001
        }
    }

    static func <(lhs: WinterGramOnlineTrackerEntry, rhs: WinterGramOnlineTrackerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramOnlineTrackerArguments
        switch self {
        case let .peer(_, peerId, name, summary):
            return ItemListDisclosureItem(presentationData: presentationData, title: name, label: summary, sectionId: self.section, style: .blocks, action: {
                arguments.openHistory(peerId)
            })
        case .clear:
            return ItemListActionItem(presentationData: presentationData, title: "Clear Tracking Log", kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.clearAll()
            })
        case .footer:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Online transitions are recorded locally while a chat is open. Tap a name to see its history."), sectionId: self.section)
        }
    }
}

private func formatEntry(_ entry: WinterGramPresenceEntry) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM HH:mm"
    return "\(formatter.string(from: date)) — \(entry.isOnline ? "online" : "offline")"
}

public func winterGramOnlineTrackerController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let refreshPromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    let arguments = WinterGramOnlineTrackerArguments(
        openHistory: { peerId in
            let entries = winterGramPresenceLog(peerId: peerId.toInt64())
            let text = entries.isEmpty ? "No records yet." : entries.reversed().prefix(40).map(formatEntry).joined(separator: "\n")
            let controller = textAlertController(context: context, title: nil, text: text, actions: [
                TextAlertAction(type: .defaultAction, title: context.sharedContext.currentPresentationData.with { $0 }.strings.Common_OK, action: {})
            ])
            presentControllerImpl?(controller, nil)
        },
        clearAll: {
            winterGramClearPresenceLog()
            refreshPromise.set(true)
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, refreshPromise.get())
    |> mapToSignal { presentationData, _ -> Signal<(ItemListControllerState, (ItemListNodeState, Any)), NoError> in
        let peerIds = winterGramTrackedPeerIds()
        let enginePeerIds = peerIds.map { EnginePeer.Id($0) }
        return context.engine.data.get(EngineDataMap(enginePeerIds.map { TelegramEngine.EngineData.Item.Peer.Peer(id: $0) }))
        |> map { peerMap -> (ItemListControllerState, (ItemListNodeState, Any)) in
            var entries: [WinterGramOnlineTrackerEntry] = []
            var index = 0
            for pid in enginePeerIds {
                let name: String
                if let maybePeer = peerMap[pid], let peer = maybePeer {
                    name = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                } else {
                    name = "\(pid.toInt64())"
                }
                let log = winterGramPresenceLog(peerId: pid.toInt64())
                let summary: String
                if let last = log.last {
                    summary = last.isOnline ? "online" : "offline"
                } else {
                    summary = ""
                }
                entries.append(.peer(index: index, peerId: pid, name: name, summary: summary))
                index += 1
            }
            if !entries.isEmpty {
                entries.append(.clear)
            }
            entries.append(.footer)

            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Online Tracker"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)
            return (controllerState, (listState, arguments))
        }
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
