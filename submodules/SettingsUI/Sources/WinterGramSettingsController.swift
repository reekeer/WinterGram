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

private final class WinterGramSettingsArguments {
    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void
    let presentSendWithoutSound: () -> Void
    let presentPeerId: () -> Void
    let presentTranslationProvider: () -> Void
    let presentWebviewPlatform: () -> Void
    let presentIconPack: () -> Void

    init(
        updateSettings: @escaping (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void,
        presentSendWithoutSound: @escaping () -> Void,
        presentPeerId: @escaping () -> Void,
        presentTranslationProvider: @escaping () -> Void,
        presentWebviewPlatform: @escaping () -> Void,
        presentIconPack: @escaping () -> Void
    ) {
        self.updateSettings = updateSettings
        self.presentSendWithoutSound = presentSendWithoutSound
        self.presentPeerId = presentPeerId
        self.presentTranslationProvider = presentTranslationProvider
        self.presentWebviewPlatform = presentWebviewPlatform
        self.presentIconPack = presentIconPack
    }
}

private enum WinterGramSettingsSection: Int32 {
    case ghost
    case history
    case stash
    case antiFeatures
    case confirmations
    case chat
    case appearance
    case liquidGlass
}

private enum WinterGramSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case ghostEnabled(Bool)
    case ghostReadReceipts(Bool)
    case ghostReadStories(Bool)
    case ghostOnlineStatus(Bool)
    case ghostUploadProgress(Bool)
    case ghostOfflineAfterOnline(Bool)
    case ghostMarkReadAfterAction(Bool)
    case ghostUseScheduled(Bool)
    case ghostSendWithoutSound(String)
    case ghostSuggestBeforeStory(Bool)
    case ghostFooter

    case historyHeader
    case historySaveDeleted(Bool)
    case historySaveEdits(Bool)
    case historySemiTransparent(Bool)
    case historyFooter

    case stashHeader
    case stashMute(Bool)
    case stashAutoRead(Bool)
    case stashFooter

    case antiHeader
    case antiDisableAds(Bool)
    case antiLocalPremium(Bool)
    case antiDisableStories(Bool)
    case antiHidePremiumStatuses(Bool)
    case antiDisableLinkWarning(Bool)
    case antiFooter

    case confirmHeader
    case confirmStickers(Bool)
    case confirmGif(Bool)
    case confirmVoice(Bool)

    case chatHeader
    case chatShowSeconds(Bool)
    case chatShowPeerId(String)
    case chatTranslate(Bool)
    case chatTranslateProvider(String)
    case chatWebviewPlatform(String)
    case chatWebviewHeight(Bool)
    case chatOnlyAddedEmoji(Bool)

    case appearanceHeader
    case appearanceMaterial(Bool)
    case appearanceSingleCorner(Bool)
    case appearanceIconPack(String)

    case glassHeader
    case glassEnabled(Bool)
    case glassVibrancy(Bool)
    case glassChatList(Bool)
    case glassNavBars(Bool)
    case glassTabBar(Bool)
    case glassBubbles(Bool)
    case glassFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostEnabled, .ghostReadReceipts, .ghostReadStories, .ghostOnlineStatus, .ghostUploadProgress, .ghostOfflineAfterOnline, .ghostMarkReadAfterAction, .ghostUseScheduled, .ghostSendWithoutSound, .ghostSuggestBeforeStory, .ghostFooter:
            return WinterGramSettingsSection.ghost.rawValue
        case .historyHeader, .historySaveDeleted, .historySaveEdits, .historySemiTransparent, .historyFooter:
            return WinterGramSettingsSection.history.rawValue
        case .stashHeader, .stashMute, .stashAutoRead, .stashFooter:
            return WinterGramSettingsSection.stash.rawValue
        case .antiHeader, .antiDisableAds, .antiLocalPremium, .antiDisableStories, .antiHidePremiumStatuses, .antiDisableLinkWarning, .antiFooter:
            return WinterGramSettingsSection.antiFeatures.rawValue
        case .confirmHeader, .confirmStickers, .confirmGif, .confirmVoice:
            return WinterGramSettingsSection.confirmations.rawValue
        case .chatHeader, .chatShowSeconds, .chatShowPeerId, .chatTranslate, .chatTranslateProvider, .chatWebviewPlatform, .chatWebviewHeight, .chatOnlyAddedEmoji:
            return WinterGramSettingsSection.chat.rawValue
        case .appearanceHeader, .appearanceMaterial, .appearanceSingleCorner, .appearanceIconPack:
            return WinterGramSettingsSection.appearance.rawValue
        case .glassHeader, .glassEnabled, .glassVibrancy, .glassChatList, .glassNavBars, .glassTabBar, .glassBubbles, .glassFooter:
            return WinterGramSettingsSection.liquidGlass.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader: return 0
        case .ghostEnabled: return 1
        case .ghostReadReceipts: return 2
        case .ghostReadStories: return 3
        case .ghostOnlineStatus: return 4
        case .ghostUploadProgress: return 5
        case .ghostOfflineAfterOnline: return 6
        case .ghostMarkReadAfterAction: return 7
        case .ghostUseScheduled: return 8
        case .ghostSendWithoutSound: return 9
        case .ghostSuggestBeforeStory: return 10
        case .ghostFooter: return 11
        case .historyHeader: return 12
        case .historySaveDeleted: return 13
        case .historySaveEdits: return 14
        case .historySemiTransparent: return 15
        case .historyFooter: return 16
        case .stashHeader: return 17
        case .stashMute: return 18
        case .stashAutoRead: return 19
        case .stashFooter: return 20
        case .antiHeader: return 21
        case .antiDisableAds: return 22
        case .antiLocalPremium: return 23
        case .antiDisableStories: return 24
        case .antiHidePremiumStatuses: return 25
        case .antiDisableLinkWarning: return 26
        case .antiFooter: return 27
        case .confirmHeader: return 28
        case .confirmStickers: return 29
        case .confirmGif: return 30
        case .confirmVoice: return 31
        case .chatHeader: return 32
        case .chatShowSeconds: return 33
        case .chatShowPeerId: return 34
        case .chatTranslate: return 35
        case .chatTranslateProvider: return 36
        case .chatWebviewPlatform: return 37
        case .chatWebviewHeight: return 38
        case .chatOnlyAddedEmoji: return 39
        case .appearanceHeader: return 40
        case .appearanceMaterial: return 41
        case .appearanceSingleCorner: return 42
        case .appearanceIconPack: return 43
        case .glassHeader: return 44
        case .glassEnabled: return 45
        case .glassVibrancy: return 46
        case .glassChatList: return 47
        case .glassNavBars: return 48
        case .glassTabBar: return 49
        case .glassBubbles: return 50
        case .glassFooter: return 51
        }
    }

    static func <(lhs: WinterGramSettingsEntry, rhs: WinterGramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramSettingsArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .ghostEnabled(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Ghost Mode", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.ghostModeEnabled = value; return s }
            })
        case let .ghostReadReceipts(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Send Read Receipts", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.sendReadReceipts = value; return s }
            })
        case let .ghostReadStories(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Send Story Views", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.sendReadStories = value; return s }
            })
        case let .ghostOnlineStatus(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Send Online Status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.sendOnlineStatus = value; return s }
            })
        case let .ghostUploadProgress(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Send Typing & Upload Status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.sendUploadProgress = value; return s }
            })
        case let .ghostOfflineAfterOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Go Offline After Online", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.sendOfflineAfterOnline = value; return s }
            })
        case let .ghostMarkReadAfterAction(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Mark Read After Action", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.markReadAfterAction = value; return s }
            })
        case let .ghostUseScheduled(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Use Scheduled Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.useScheduledMessages = value; return s }
            })
        case let .ghostSendWithoutSound(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Send Without Sound", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.presentSendWithoutSound()
            })
        case let .ghostSuggestBeforeStory(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Ask Before Viewing Stories", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.suggestGhostBeforeStory = value; return s }
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("When Ghost Mode is on, WinterGram stops sending read receipts, online status and typing activity."), sectionId: self.section)

        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "HISTORY", sectionId: self.section)
        case let .historySaveDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Deleted Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveDeletedMessages = value; return s }
            })
        case let .historySaveEdits(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Edit History", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveMessagesHistory = value; return s }
            })
        case let .historySemiTransparent(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Dim Deleted Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.semiTransparentDeletedMessages = value; return s }
            })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Deleted and edited messages are kept locally on this device only."), sectionId: self.section)

        case .stashHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "HIDDEN ARCHIVE", sectionId: self.section)
        case let .stashMute(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Mute Notifications", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stashMuteNotifications = value; return s }
            })
        case let .stashAutoRead(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Auto Mark as Read", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stashAutoMarkRead = value; return s }
            })
        case .stashFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Stashed chats are hidden from the main list and accessible only here."), sectionId: self.section)

        case .antiHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "FEATURES", sectionId: self.section)
        case let .antiDisableAds(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Disable Ads", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableAds = value; return s }
            })
        case let .antiLocalPremium(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Local Premium", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.localPremium = value; return s }
            })
        case let .antiDisableStories(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide Stories", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableStories = value; return s }
            })
        case let .antiHidePremiumStatuses(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide Premium Statuses", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.hidePremiumStatuses = value; return s }
            })
        case let .antiDisableLinkWarning(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Disable Open Link Warning", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableOpenLinkWarning = value; return s }
            })
        case .antiFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Local Premium unlocks Premium-only UI on this device; it does not grant server-side Premium."), sectionId: self.section)

        case .confirmHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SEND CONFIRMATIONS", sectionId: self.section)
        case let .confirmStickers(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Confirm Stickers", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stickerConfirmation = value; return s }
            })
        case let .confirmGif(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Confirm GIFs", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.gifConfirmation = value; return s }
            })
        case let .confirmVoice(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Confirm Voice Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.voiceConfirmation = value; return s }
            })

        case .chatHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "CHAT", sectionId: self.section)
        case let .chatShowSeconds(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Show Message Seconds", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.showMessageSeconds = value; return s }
            })
        case let .chatShowPeerId(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Show Peer ID", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.presentPeerId()
            })
        case let .chatTranslate(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Message Translation", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.translateMessages = value; return s }
            })
        case let .chatTranslateProvider(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Translation Provider", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.presentTranslationProvider()
            })
        case let .chatWebviewPlatform(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "WebView Platform", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.presentWebviewPlatform()
            })
        case let .chatWebviewHeight(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Increase WebView Height", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.increaseWebviewHeight = value; return s }
            })
        case let .chatOnlyAddedEmoji(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Only Added Emoji & Stickers", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.showOnlyAddedEmojisAndStickers = value; return s }
            })

        case .appearanceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "APPEARANCE", sectionId: self.section)
        case let .appearanceMaterial(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Material Design", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.materialDesign = value; return s }
            })
        case let .appearanceSingleCorner(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Single Corner Radius", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.singleCornerRadius = value; return s }
            })
        case let .appearanceIconPack(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Icon Pack", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.presentIconPack()
            })

        case .glassHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "LIQUID GLASS", sectionId: self.section)
        case let .glassEnabled(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Liquid Glass", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.enabled = value; return s }
            })
        case let .glassVibrancy(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Vibrancy", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.vibrancy = value; return s }
            })
        case let .glassChatList(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Apply to Chat List", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToChatList = value; return s }
            })
        case let .glassNavBars(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Apply to Navigation Bars", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToNavigationBars = value; return s }
            })
        case let .glassTabBar(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Apply to Tab Bar", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToTabBar = value; return s }
            })
        case let .glassBubbles(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Apply to Bubbles", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToBubbles = value; return s }
            })
        case .glassFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Transparency, blur and tint can be fine-tuned per surface. Turn Liquid Glass off for the standard opaque look."), sectionId: self.section)
        }
    }
}

private func sendWithoutSoundLabel(_ value: WinterGramSendWithoutSound) -> String {
    switch value {
    case .never: return "Never"
    case .inGhostMode: return "In Ghost Mode"
    case .always: return "Always"
    }
}

private func peerIdLabel(_ value: WinterGramPeerIdDisplay) -> String {
    switch value {
    case .hidden: return "Hidden"
    case .telegramApi: return "Telegram API"
    case .botApi: return "Bot API"
    }
}

private func translationProviderLabel(_ value: WinterGramTranslationProvider) -> String {
    switch value {
    case .telegram: return "Telegram"
    case .google: return "Google"
    case .yandex: return "Yandex"
    case .system: return "System"
    }
}

private func webviewPlatformLabel(_ value: WinterGramWebviewPlatform) -> String {
    switch value {
    case .auto: return "Automatic"
    case .ios: return "iOS"
    case .android: return "Android"
    case .macos: return "macOS"
    case .desktop: return "Desktop"
    }
}

private func iconPackLabel(_ value: WinterGramIconPack) -> String {
    switch value {
    case .wintergram: return "WinterGram"
    case .ayugram: return "AyuGram"
    case .exteragram: return "exteraGram"
    case .telegram: return "Telegram"
    }
}

private func winterGramSettingsEntries(settings: WinterGramSettings) -> [WinterGramSettingsEntry] {
    var entries: [WinterGramSettingsEntry] = []

    entries.append(.ghostHeader)
    entries.append(.ghostEnabled(settings.ghostModeEnabled))
    entries.append(.ghostReadReceipts(settings.sendReadReceipts))
    entries.append(.ghostReadStories(settings.sendReadStories))
    entries.append(.ghostOnlineStatus(settings.sendOnlineStatus))
    entries.append(.ghostUploadProgress(settings.sendUploadProgress))
    entries.append(.ghostOfflineAfterOnline(settings.sendOfflineAfterOnline))
    entries.append(.ghostMarkReadAfterAction(settings.markReadAfterAction))
    entries.append(.ghostUseScheduled(settings.useScheduledMessages))
    entries.append(.ghostSendWithoutSound(sendWithoutSoundLabel(settings.sendWithoutSound)))
    entries.append(.ghostSuggestBeforeStory(settings.suggestGhostBeforeStory))
    entries.append(.ghostFooter)

    entries.append(.historyHeader)
    entries.append(.historySaveDeleted(settings.saveDeletedMessages))
    entries.append(.historySaveEdits(settings.saveMessagesHistory))
    entries.append(.historySemiTransparent(settings.semiTransparentDeletedMessages))
    entries.append(.historyFooter)

    entries.append(.stashHeader)
    entries.append(.stashMute(settings.stashMuteNotifications))
    entries.append(.stashAutoRead(settings.stashAutoMarkRead))
    entries.append(.stashFooter)

    entries.append(.antiHeader)
    entries.append(.antiDisableAds(settings.disableAds))
    entries.append(.antiLocalPremium(settings.localPremium))
    entries.append(.antiDisableStories(settings.disableStories))
    entries.append(.antiHidePremiumStatuses(settings.hidePremiumStatuses))
    entries.append(.antiDisableLinkWarning(settings.disableOpenLinkWarning))
    entries.append(.antiFooter)

    entries.append(.confirmHeader)
    entries.append(.confirmStickers(settings.stickerConfirmation))
    entries.append(.confirmGif(settings.gifConfirmation))
    entries.append(.confirmVoice(settings.voiceConfirmation))

    entries.append(.chatHeader)
    entries.append(.chatShowSeconds(settings.showMessageSeconds))
    entries.append(.chatShowPeerId(peerIdLabel(settings.showPeerId)))
    entries.append(.chatTranslate(settings.translateMessages))
    entries.append(.chatTranslateProvider(translationProviderLabel(settings.translationProvider)))
    entries.append(.chatWebviewPlatform(webviewPlatformLabel(settings.webviewSpoofPlatform)))
    entries.append(.chatWebviewHeight(settings.increaseWebviewHeight))
    entries.append(.chatOnlyAddedEmoji(settings.showOnlyAddedEmojisAndStickers))

    entries.append(.appearanceHeader)
    entries.append(.appearanceMaterial(settings.materialDesign))
    entries.append(.appearanceSingleCorner(settings.singleCornerRadius))
    entries.append(.appearanceIconPack(iconPackLabel(settings.iconPack)))

    entries.append(.glassHeader)
    entries.append(.glassEnabled(settings.liquidGlass.enabled))
    entries.append(.glassVibrancy(settings.liquidGlass.vibrancy))
    entries.append(.glassChatList(settings.liquidGlass.applyToChatList))
    entries.append(.glassNavBars(settings.liquidGlass.applyToNavigationBars))
    entries.append(.glassTabBar(settings.liquidGlass.applyToTabBar))
    entries.append(.glassBubbles(settings.liquidGlass.applyToBubbles))
    entries.append(.glassFooter)

    return entries
}

public func winterGramSettingsController(context: AccountContext) -> ViewController {
    let accountManager = context.sharedContext.accountManager

    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void = { f in
        let _ = updateWinterGramSettingsInteractively(accountManager: accountManager, f).start()
    }

    func presentChoice<T>(title: String, options: [(String, T)], apply: @escaping (T, WinterGramSettings) -> WinterGramSettings) {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = []
        items.append(ActionSheetTextItem(title: title))
        for (label, value) in options {
            items.append(ActionSheetButtonItem(title: label, action: { [weak controller] in
                controller?.dismissAnimated()
                updateSettings { apply(value, $0) }
            }))
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak controller] in
                    controller?.dismissAnimated()
                })
            ])
        ])
        presentControllerImpl?(controller, nil)
    }

    let arguments = WinterGramSettingsArguments(
        updateSettings: updateSettings,
        presentSendWithoutSound: {
            presentChoice(title: "Send Without Sound", options: [
                ("Never", WinterGramSendWithoutSound.never),
                ("In Ghost Mode", WinterGramSendWithoutSound.inGhostMode),
                ("Always", WinterGramSendWithoutSound.always)
            ], apply: { value, settings in
                var settings = settings
                settings.sendWithoutSound = value
                return settings
            })
        },
        presentPeerId: {
            presentChoice(title: "Show Peer ID", options: [
                ("Hidden", WinterGramPeerIdDisplay.hidden),
                ("Telegram API", WinterGramPeerIdDisplay.telegramApi),
                ("Bot API", WinterGramPeerIdDisplay.botApi)
            ], apply: { value, settings in
                var settings = settings
                settings.showPeerId = value
                return settings
            })
        },
        presentTranslationProvider: {
            presentChoice(title: "Translation Provider", options: [
                ("Telegram", WinterGramTranslationProvider.telegram),
                ("Google", WinterGramTranslationProvider.google),
                ("Yandex", WinterGramTranslationProvider.yandex),
                ("System", WinterGramTranslationProvider.system)
            ], apply: { value, settings in
                var settings = settings
                settings.translationProvider = value
                return settings
            })
        },
        presentWebviewPlatform: {
            presentChoice(title: "WebView Platform", options: [
                ("Automatic", WinterGramWebviewPlatform.auto),
                ("iOS", WinterGramWebviewPlatform.ios),
                ("Android", WinterGramWebviewPlatform.android),
                ("macOS", WinterGramWebviewPlatform.macos),
                ("Desktop", WinterGramWebviewPlatform.desktop)
            ], apply: { value, settings in
                var settings = settings
                settings.webviewSpoofPlatform = value
                return settings
            })
        },
        presentIconPack: {
            presentChoice(title: "Icon Pack", options: [
                ("WinterGram", WinterGramIconPack.wintergram),
                ("AyuGram", WinterGramIconPack.ayugram),
                ("exteraGram", WinterGramIconPack.exteragram),
                ("Telegram", WinterGramIconPack.telegram)
            ], apply: { value, settings in
                var settings = settings
                settings.iconPack = value
                return settings
            })
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        winterGramSettings(accountManager: accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("WinterGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: winterGramSettingsEntries(settings: settings), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
