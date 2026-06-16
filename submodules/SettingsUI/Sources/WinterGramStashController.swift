import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import ItemListPeerItem
import PresentationDataUtils
import AccountContext

private final class WinterGramStashArguments {
    let context: AccountContext
    let openPeer: (EnginePeer) -> Void
    let removePeer: (EnginePeer.Id) -> Void
    let updateRevealedPeerId: (EnginePeer.Id?) -> Void

    init(
        context: AccountContext,
        openPeer: @escaping (EnginePeer) -> Void,
        removePeer: @escaping (EnginePeer.Id) -> Void,
        updateRevealedPeerId: @escaping (EnginePeer.Id?) -> Void
    ) {
        self.context = context
        self.openPeer = openPeer
        self.removePeer = removePeer
        self.updateRevealedPeerId = updateRevealedPeerId
    }
}

private enum WinterGramStashSection: Int32 {
    case peers
}

private enum WinterGramStashEntry: ItemListNodeEntry {
    case header
    case peer(Int32, EnginePeer, Bool)
    case empty

    var section: ItemListSectionId {
        return WinterGramStashSection.peers.rawValue
    }

    var stableId: Int64 {
        switch self {
        case .header:
            return 0
        case let .peer(_, peer, _):
            return peer.id.id._internalGetInt64Value()
        case .empty:
            return 1
        }
    }

    static func ==(lhs: WinterGramStashEntry, rhs: WinterGramStashEntry) -> Bool {
        switch lhs {
        case .header:
            if case .header = rhs {
                return true
            }
            return false
        case let .peer(lhsIndex, lhsPeer, lhsRevealed):
            if case let .peer(rhsIndex, rhsPeer, rhsRevealed) = rhs, lhsIndex == rhsIndex, lhsPeer == rhsPeer, lhsRevealed == rhsRevealed {
                return true
            }
            return false
        case .empty:
            if case .empty = rhs {
                return true
            }
            return false
        }
    }

    static func <(lhs: WinterGramStashEntry, rhs: WinterGramStashEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int32 {
        switch self {
        case .header:
            return 0
        case let .peer(index, _, _):
            return 10 + index
        case .empty:
            return 1
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramStashArguments
        switch self {
        case .header:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.WinterGram_HiddenArchiveInfo), sectionId: self.section)
        case let .peer(_, peer, revealed):
            let chatPresentationData = arguments.context.sharedContext.currentPresentationData.with { $0 }
            return ItemListPeerItem(presentationData: presentationData, dateTimeFormat: chatPresentationData.dateTimeFormat, nameDisplayOrder: chatPresentationData.nameDisplayOrder, context: arguments.context, peer: peer, presence: nil, text: .none, label: .none, editing: ItemListPeerItemEditing(editable: true, editing: false, revealed: revealed), switchValue: nil, enabled: true, selectable: true, sectionId: self.section, action: {
                arguments.openPeer(peer)
            }, setPeerIdWithRevealedOptions: { peerId, _ in
                arguments.updateRevealedPeerId(peerId)
            }, removePeer: { peerId in
                arguments.removePeer(peerId)
            })
        case .empty:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.WinterGram_HiddenArchiveEmpty), sectionId: self.section)
        }
    }
}

public func winterGramStashController(context: AccountContext) -> ViewController {
    let revealedPeerId = ValuePromise<EnginePeer.Id?>(nil)
    let revealedPeerIdValue = Atomic<EnginePeer.Id?>(value: nil)

    let accountManager = context.sharedContext.accountManager

    let arguments = WinterGramStashArguments(
        context: context,
        openPeer: { peer in
            if let navigationController = context.sharedContext.mainWindow?.viewController as? NavigationController {
                context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: context, chatLocation: .peer(peer)))
            }
        },
        removePeer: { peerId in
            let rawId = peerId.toInt64()
            let _ = updateWinterGramSettingsInteractively(accountManager: accountManager, { settings in
                var settings = settings
                settings.stashedPeerIds.removeAll(where: { $0 == rawId })
                return settings
            }).start()
            // Remove the peer from the server-side privacy exceptions added when it was stashed.
            let _ = winterGramApplyStashPrivacy(engine: context.engine, peerId: peerId, stashed: false, privacySettings: currentWinterGramSettings.stashPrivacy).startStandalone()
        },
        updateRevealedPeerId: { peerId in
            let _ = revealedPeerIdValue.swap(peerId)
            revealedPeerId.set(peerId)
        }
    )

    let peers = winterGramSettings(accountManager: accountManager)
    |> map { settings -> [EnginePeer.Id] in
        var seen = Set<Int64>()
        var result: [EnginePeer.Id] = []
        for rawPeerId in settings.stashedPeerIds {
            if seen.insert(rawPeerId).inserted {
                result.append(EnginePeer.Id(rawPeerId))
            }
        }
        return result
    }
    |> distinctUntilChanged
    |> mapToSignal { peerIds -> Signal<[EnginePeer], NoError> in
        return context.engine.data.subscribe(
            EngineDataMap(peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:)))
        )
        |> map { peerMap -> [EnginePeer] in
            var result: [EnginePeer] = []
            for id in peerIds {
                if let maybePeer = peerMap[id], let peer = maybePeer {
                    result.append(peer)
                }
            }
            return result
        }
    }

    let signal = combineLatest(
        context.sharedContext.presentationData,
        peers,
        revealedPeerId.get()
    )
    |> map { presentationData, peers, revealedPeerId -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [WinterGramStashEntry] = []
        entries.append(.header)
        if peers.isEmpty {
            entries.append(.empty)
        } else {
            var index: Int32 = 0
            for peer in peers {
                entries.append(.peer(index, peer, revealedPeerId == peer.id))
                index += 1
            }
        }

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.WinterGram_HiddenArchive), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
