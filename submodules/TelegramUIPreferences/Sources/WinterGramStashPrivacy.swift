import Foundation
import TelegramCore
import SwiftSignalKit

// WinterGram: when a chat is moved into / out of the Hidden Archive we can add (or remove) the peer
// in the "exceptions" of the selected privacy categories. Only `.enableEveryone` is touched: this
// mirrors Telegram's "Everybody Except..." behavior and does not change other privacy categories.
//
// `stashed == true` adds the peer to every enabled exception list; `false` removes it from all lists.
public func winterGramApplyStashPrivacy(engine: TelegramEngine, peerId: EnginePeer.Id, stashed: Bool, privacySettings: WinterGramStashPrivacySettings) -> Signal<Never, NoError> {
    return combineLatest(
        engine.privacy.requestAccountPrivacySettings() |> take(1),
        engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
    )
    |> mapToSignal { settings, maybePeer -> Signal<Never, NoError> in
        guard let peer = maybePeer else {
            return .complete()
        }

        let privacyPeer = SelectivePrivacyPeer(peer: peer, participantCount: nil)
        var updates: [Signal<Void, NoError>] = []

        func adjust(_ current: SelectivePrivacySettings, type: UpdateSelectiveAccountPrivacySettingsType, enabled: Bool) {
            guard case let .enableEveryone(disableFor) = current else {
                return
            }
            var newDisableFor = disableFor
            if stashed && enabled {
                if newDisableFor[peerId] == nil {
                    newDisableFor[peerId] = privacyPeer
                }
            } else {
                newDisableFor.removeValue(forKey: peerId)
            }
            if newDisableFor != disableFor {
                updates.append(engine.privacy.updateSelectiveAccountPrivacySettings(type: type, settings: .enableEveryone(disableFor: newDisableFor)))
            }
        }

        adjust(settings.profilePhoto, type: .profilePhoto, enabled: privacySettings.profilePhoto)
        adjust(settings.phoneNumber, type: .phoneNumber, enabled: privacySettings.phoneNumber)
        adjust(settings.presence, type: .presence, enabled: privacySettings.presence)
        adjust(settings.forwards, type: .forwards, enabled: privacySettings.forwards)
        adjust(settings.voiceCalls, type: .voiceCalls, enabled: privacySettings.voiceCalls)
        adjust(settings.birthday, type: .birthday, enabled: privacySettings.birthday)
        adjust(settings.giftsAutoSave, type: .giftsAutoSave, enabled: privacySettings.giftsAutoSave)
        adjust(settings.bio, type: .bio, enabled: privacySettings.bio)
        adjust(settings.savedMusic, type: .savedMusic, enabled: privacySettings.savedMusic)
        adjust(settings.groupInvitations, type: .groupInvitations, enabled: privacySettings.groupInvitations)

        if updates.isEmpty {
            return .complete()
        }
        return combineLatest(updates)
        |> ignoreValues
    }
}
