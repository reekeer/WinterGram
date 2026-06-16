import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import ItemListPeerActionItem
import PresentationDataUtils
import AccountContext
import PromptUI
import UndoUI

private final class WinterGramSettingsArguments {
    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void
    let toggleDropdown: (WinterGramDropdown) -> Void
    let selectDropdownOption: (WinterGramDropdown, Int) -> Void
    let toggleGhostExpanded: () -> Void
    let editSpoofDevice: () -> Void
    let addSpoofTemplate: () -> Void
    let toggleSpoofTemplateSelected: (Int) -> Void
    let deleteSelectedSpoofTemplates: () -> Void
    let editApiId: () -> Void
    let editApiHash: () -> Void
    let openStash: () -> Void
    let editStashPasscode: () -> Void
    let editDeletedMark: () -> Void
    let context: AccountContext
    let openUrl: (String) -> Void
    let clearDeleted: () -> Void

    init(
        context: AccountContext,
        updateSettings: @escaping (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void,
        toggleDropdown: @escaping (WinterGramDropdown) -> Void,
        selectDropdownOption: @escaping (WinterGramDropdown, Int) -> Void,
        toggleGhostExpanded: @escaping () -> Void,
        editSpoofDevice: @escaping () -> Void,
        addSpoofTemplate: @escaping () -> Void,
        toggleSpoofTemplateSelected: @escaping (Int) -> Void,
        deleteSelectedSpoofTemplates: @escaping () -> Void,
        editApiId: @escaping () -> Void,
        editApiHash: @escaping () -> Void,
        openStash: @escaping () -> Void,
        editStashPasscode: @escaping () -> Void,
        editDeletedMark: @escaping () -> Void,
        openUrl: @escaping (String) -> Void,
        clearDeleted: @escaping () -> Void
    ) {
        self.updateSettings = updateSettings
        self.toggleDropdown = toggleDropdown
        self.selectDropdownOption = selectDropdownOption
        self.toggleGhostExpanded = toggleGhostExpanded
        self.editSpoofDevice = editSpoofDevice
        self.addSpoofTemplate = addSpoofTemplate
        self.toggleSpoofTemplateSelected = toggleSpoofTemplateSelected
        self.deleteSelectedSpoofTemplates = deleteSelectedSpoofTemplates
        self.editApiId = editApiId
        self.editApiHash = editApiHash
        self.openStash = openStash
        self.editStashPasscode = editStashPasscode
        self.editDeletedMark = editDeletedMark
        self.context = context
        self.openUrl = openUrl
        self.clearDeleted = clearDeleted
    }
}

public enum WinterGramSettingsSection: Int32, CaseIterable {
    case banner
    case ghost
    case history
    case stash
    case antiFeatures
    case chat
    case liquidGlass
    case spoofing
    // Combined "super-categories" shown in the redesigned main menu.
    case ayugram   // Ghost Mode + History + Hidden Archive
    case other     // Chat tweaks + Spoofing (show id, registration date, spoofer, …)

    public var title: String {
        switch self {
        case .banner:
            return ""
        case .ghost:
            return "Ghost Mode"
        case .history:
            return "History"
        case .stash:
            return "Hidden Archive"
        case .antiFeatures:
            return "Features"
        case .chat:
            return "Chat"
        case .liquidGlass:
            return "Liquid Glass"
        case .spoofing:
            return "Spoofing"
        case .ayugram:
            return "Core"
        case .other:
            return "Other"
        }
    }

    public var iconName: String {
        // SF Symbols used for the main menu cells.
        switch self {
        case .banner:
            return ""
        case .ghost:
            return "eye.slash"
        case .history:
            return "clock.arrow.circlepath"
        case .stash:
            return "archivebox"
        case .antiFeatures:
            return "sparkles"
        case .chat:
            return "message"
        case .liquidGlass:
            return "drop"
        case .spoofing:
            return "theatermasks"
        case .ayugram:
            return "shield.fill"
        case .other:
            return "ellipsis.circle"
        }
    }

    // Maps a deep-link path/section name (wnt://wintergram/<name>) to a settings subtab.
    public init?(deepLinkName: String) {
        switch deepLinkName.lowercased() {
        case "ghost", "ghostmode": self = .ghost
        case "history": self = .history
        case "stash", "archive", "hiddenarchive": self = .stash
        case "features", "antifeatures", "anti": self = .antiFeatures
        case "chat": self = .chat
        case "glass", "liquidglass": self = .liquidGlass
        case "spoofing", "spoof": self = .spoofing
        case "ayugram", "ayu": self = .ayugram
        case "other", "misc": self = .other
        default: return nil
        }
    }
}

private enum WinterGramDropdown: Equatable {
    case sendWithoutSound
    case peerId
    case translationProvider
    case webviewPlatform
    case stashPrivacy
}

// Single source of truth for each inline dropdown's options: display title (English; localized at
// render time), whether it is the current selection, and how to apply it.
private func winterGramDropdownOptions(_ dropdown: WinterGramDropdown, settings: WinterGramSettings) -> [(title: String, selected: Bool, apply: (WinterGramSettings) -> WinterGramSettings)] {
    switch dropdown {
    case .stashPrivacy:
        let p = settings.stashPrivacy
        return [
            ("Profile Photo", p.profilePhoto, { s in var s = s; s.stashPrivacy.profilePhoto = !s.stashPrivacy.profilePhoto; return s }),
            ("Phone Number", p.phoneNumber, { s in var s = s; s.stashPrivacy.phoneNumber = !s.stashPrivacy.phoneNumber; return s }),
            ("Last Seen", p.presence, { s in var s = s; s.stashPrivacy.presence = !s.stashPrivacy.presence; return s }),
            ("Forwards", p.forwards, { s in var s = s; s.stashPrivacy.forwards = !s.stashPrivacy.forwards; return s }),
            ("Voice Calls", p.voiceCalls, { s in var s = s; s.stashPrivacy.voiceCalls = !s.stashPrivacy.voiceCalls; return s }),
            ("Birthday", p.birthday, { s in var s = s; s.stashPrivacy.birthday = !s.stashPrivacy.birthday; return s }),
            ("Gifts Auto-Save", p.giftsAutoSave, { s in var s = s; s.stashPrivacy.giftsAutoSave = !s.stashPrivacy.giftsAutoSave; return s }),
            ("Bio", p.bio, { s in var s = s; s.stashPrivacy.bio = !s.stashPrivacy.bio; return s }),
            ("Saved Music", p.savedMusic, { s in var s = s; s.stashPrivacy.savedMusic = !s.stashPrivacy.savedMusic; return s }),
            ("Group Invitations", p.groupInvitations, { s in var s = s; s.stashPrivacy.groupInvitations = !s.stashPrivacy.groupInvitations; return s })
        ]
    case .sendWithoutSound:
        let v = settings.sendWithoutSound
        return [
            ("Never", v == .never, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.sendWithoutSound = .never; return s }),
            ("In Ghost Mode", v == .inGhostMode, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.sendWithoutSound = .inGhostMode; return s }),
            ("Always", v == .always, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.sendWithoutSound = .always; return s })
        ]
    case .peerId:
        let v = settings.showPeerId
        return [
            ("Hidden", v == .hidden, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.showPeerId = .hidden; return s }),
            ("Telegram API", v == .telegramApi, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.showPeerId = .telegramApi; return s }),
            ("Bot API", v == .botApi, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.showPeerId = .botApi; return s })
        ]
    case .translationProvider:
        let v = settings.translationProvider
        return [
            ("Disabled", !settings.translateMessages, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.translateMessages = false; return s }),
            ("Telegram", settings.translateMessages && v == .telegram, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.translateMessages = true; s.translationProvider = .telegram; return s }),
            ("Google", settings.translateMessages && v == .google, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.translateMessages = true; s.translationProvider = .google; return s }),
            ("Yandex", settings.translateMessages && v == .yandex, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.translateMessages = true; s.translationProvider = .yandex; return s }),
            ("System", settings.translateMessages && v == .system, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.translateMessages = true; s.translationProvider = .system; return s })
        ]
    case .webviewPlatform:
        let v = settings.webviewSpoofPlatform
        return [
            ("Automatic", v == .auto, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.webviewSpoofPlatform = .auto; return s }),
            ("iOS", v == .ios, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.webviewSpoofPlatform = .ios; return s }),
            ("Android", v == .android, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.webviewSpoofPlatform = .android; return s }),
            ("macOS", v == .macos, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.webviewSpoofPlatform = .macos; return s }),
            ("Desktop", v == .desktop, { (s: WinterGramSettings) -> WinterGramSettings in var s = s; s.webviewSpoofPlatform = .desktop; return s })
        ]
    }
}

// Built-in device-model spoof presets shown as tappable cards in the Spoofing section.
// `model` is the string reported to Telegram (nil = the device's real model). `subtitle` describes it.
private let winterGramDevicePresets: [(name: String, subtitle: String, model: String?)] = [
    ("Real device", "Report this device's real model", nil),
    ("iPhone 16 Pro Max", "iPhone17,2 · A18 Pro", "iPhone 16 Pro Max"),
    ("iPhone 15 Pro Max", "iPhone16,2 · A17 Pro", "iPhone 15 Pro Max"),
    ("iPhone 15 Pro", "iPhone16,1 · A17 Pro", "iPhone 15 Pro"),
    ("iPhone 15", "iPhone15,4 · A16", "iPhone 15"),
    ("iPhone 14 Pro Max", "iPhone15,3 · A16", "iPhone 14 Pro Max"),
    ("iPhone 14", "iPhone14,7 · A15", "iPhone 14"),
    ("iPhone 13 Pro", "iPhone14,2 · A15", "iPhone 13 Pro"),
    ("iPhone 13 mini", "iPhone14,4 · A15", "iPhone 13 mini"),
    ("iPhone 12", "iPhone13,2 · A14", "iPhone 12"),
    ("iPhone SE (3rd gen)", "iPhone14,6 · A15", "iPhone SE (3rd generation)"),
    ("iPhone X", "iPhone10,3 · A11", "iPhone X"),
    ("iPad Pro M4", "iPad16,3 · Apple M4", "iPad Pro M4"),
    ("Google Pixel 10 Pro", "Pixel 10 Pro · Tensor G5", "Pixel 10 Pro"),
    ("Samsung Galaxy S25 Ultra", "SM-S938U · Snapdragon 8 Elite", "Samsung Galaxy S25 Ultra"),
    ("OnePlus 13", "CPH2649 · Snapdragon 8 Elite", "OnePlus 13"),
    ("Windows 11", "Windows NT 10.0 · x64", "Windows 11"),
    ("Windows 10", "Windows NT 10.0 · x64", "Windows 10"),
    ("Linux Desktop", "Linux · x86_64", "Linux Desktop"),
    ("macOS Sequoia", "Mac15,9 · Apple M3 Max", "macOS Sequoia")
]

private enum WinterGramSettingsEntry: ItemListNodeEntry {
    case banner

    case ghostHeader
    case ghostExpandable(Bool, Bool, [ItemListExpandableSwitchItem.SubItem])
    case ghostSendWithoutSound(String)
    case ghostUseScheduledMessages(Bool)
    case ghostConfirmStory(Bool)
    case ghostMarkReadAfterAction(Bool)
    case ghostFooter

    case historyHeader
    case historyHeaderSpy
    case historySaveDeleted(Bool)
    case historySaveEdits(Bool)
    case historySaveForBots(Bool)
    case historySaveSelfDestruct(Bool)
    case historySemiTransparent(Bool)
    case historyDeletedMark(String)
    case historyShowDeletedTime(Bool)
    case historyFooter

    case stashHeader
    case stashList(Int)
    case stashMute(Bool)
    case stashAutoRead(Bool)
    case stashPasscodeRow(String)
    case stashFooter

    case antiHeader
    case antiDisableAds(Bool)
    case antiLocalPremium(Bool)
    case antiDisableStories(Bool)
    case antiHidePremiumStatuses(Bool)
    case antiDisableLinkWarning(Bool)
    case antiDisableCopyProtection(Bool)
    case antiAllowScreenshots(Bool)
    case antiFooter

    case confirmStickers(Bool)
    case confirmGif(Bool)
    case confirmVoice(Bool)

    case chatHeader
    case chatPreview(PresentationTheme, TelegramWallpaper, PresentationFontSize, PresentationChatBubbleCorners, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder, [ChatPreviewMessageItem])
    case chatShowPeerId(String)
    case chatShowRegistrationDate(Bool)
    case chatHideEditedMark(Bool)
    case chatTranslateProvider(String)
    case chatWebviewHeight(Bool)
    case chatOnlyAddedEmoji(Bool)
    case chatForwardWithoutAuthor(Bool)
    case chatFooter

    case glassHeader
    case glassEnabled(Bool)
    case glassVibrancy(Bool)
    case glassChatList(Bool)
    case glassNavBars(Bool)
    case glassTabBar(Bool)
    case glassBubbles(Bool)
    case glassFooter

    case spoofingHeader
    case spoofPresetsHeader
    case spoofPreset(Int, String, String, Bool, Bool)
    case spoofAddTemplate
    case spoofDeleteSelected
    case spoofingDevice(String)
    case spoofingDevicePreset(Int, Bool)
    case spoofingWebviewPlatform(String)
    case spoofingApiId(String)
    case spoofingApiHash(String)
    case spoofingFooter

    // Expandable single-select row: dropdown key, title, expanded flag, options.
    case expandableSelection(WinterGramDropdown, String, Bool, [ItemListExpandableSelectionItem.Option])

    var section: ItemListSectionId {
        switch self {
        case .banner:
            return WinterGramSettingsSection.banner.rawValue
        case .ghostHeader, .ghostExpandable, .ghostSendWithoutSound, .ghostUseScheduledMessages, .ghostConfirmStory, .ghostMarkReadAfterAction, .ghostFooter:
            return WinterGramSettingsSection.ghost.rawValue
        case .expandableSelection(let dropdown, _, _, _):
            switch dropdown {
            case .sendWithoutSound:
                return WinterGramSettingsSection.ghost.rawValue
            case .peerId:
                return WinterGramSettingsSection.chat.rawValue
            case .translationProvider:
                return WinterGramSettingsSection.chat.rawValue
            case .webviewPlatform:
                return WinterGramSettingsSection.spoofing.rawValue
            case .stashPrivacy:
                return WinterGramSettingsSection.stash.rawValue
            }
        case .historyHeader, .historyHeaderSpy, .historySaveDeleted, .historySaveEdits, .historySaveForBots, .historySaveSelfDestruct, .historySemiTransparent, .historyDeletedMark, .historyShowDeletedTime, .historyFooter:
            return WinterGramSettingsSection.history.rawValue
        case .stashHeader, .stashList, .stashMute, .stashAutoRead, .stashPasscodeRow, .stashFooter:
            return WinterGramSettingsSection.stash.rawValue
        case .antiHeader, .antiDisableAds, .antiLocalPremium, .antiDisableStories, .antiHidePremiumStatuses, .antiDisableLinkWarning, .antiDisableCopyProtection, .antiAllowScreenshots, .antiFooter:
            return WinterGramSettingsSection.antiFeatures.rawValue
        case .confirmStickers, .confirmGif, .confirmVoice:
            return WinterGramSettingsSection.chat.rawValue
        case .chatHeader, .chatPreview, .chatShowPeerId, .chatShowRegistrationDate, .chatHideEditedMark, .chatTranslateProvider, .chatWebviewHeight, .chatOnlyAddedEmoji, .chatForwardWithoutAuthor, .chatFooter:
            return WinterGramSettingsSection.chat.rawValue
        case .glassHeader, .glassEnabled, .glassVibrancy, .glassChatList, .glassNavBars, .glassTabBar, .glassBubbles, .glassFooter:
            return WinterGramSettingsSection.liquidGlass.rawValue
        case .spoofingHeader, .spoofingDevice, .spoofingDevicePreset, .spoofingWebviewPlatform, .spoofingApiId, .spoofingApiHash, .spoofPresetsHeader, .spoofPreset, .spoofAddTemplate, .spoofDeleteSelected, .spoofingFooter:
            return WinterGramSettingsSection.spoofing.rawValue
        }
    }

    var stableId: Int32 {
        // Device preset cards nest between spoofingDevice (30000) and WebView platform (40000).
        if case let .spoofingDevicePreset(index, _) = self {
            return 30100 + Int32(index)
        }
        return self.baseStableId * 100
    }

    private var baseStableId: Int32 {
        switch self {
        case .banner: return -1
        case .ghostHeader: return 0
        case .ghostExpandable: return 2
        case .ghostSendWithoutSound: return 3
        case .ghostUseScheduledMessages: return 4
        case .ghostConfirmStory: return 5
        case .ghostMarkReadAfterAction: return 6
        case .ghostFooter: return 7
        case .historyHeader: return 10
        case .historyHeaderSpy: return 11
        case .historySaveDeleted: return 12
        case .historySaveEdits: return 13
        case .historySaveForBots: return 14
        case .historySaveSelfDestruct: return 15
        case .historySemiTransparent: return 16
        case .historyDeletedMark: return 17
        case .historyShowDeletedTime: return 18
        case .historyFooter: return 19
        case .stashHeader: return 20
        case .stashList: return 21
        case .stashMute: return 23
        case .stashAutoRead: return 24
        case .stashPasscodeRow: return 25
        case .stashFooter: return 37
        case .antiHeader: return 30
        case .antiDisableAds: return 31
        case .antiLocalPremium: return 32
        case .antiDisableStories: return 33
        case .antiHidePremiumStatuses: return 34
        case .antiDisableLinkWarning: return 35
        case .antiDisableCopyProtection: return 36
        case .antiAllowScreenshots: return 37
        case .antiFooter: return 38
        case .confirmStickers: return 64
        case .confirmGif: return 65
        case .confirmVoice: return 66
        case .chatHeader: return 48
        case .chatPreview: return 49
        case .chatShowPeerId: return 52
        case .chatShowRegistrationDate: return 53
        case .chatHideEditedMark: return 54
        case .chatTranslateProvider: return 56
        case .chatWebviewHeight: return 58
        case .chatOnlyAddedEmoji: return 59
        case .chatForwardWithoutAuthor: return 60
        case .chatFooter: return 67
        case .glassHeader: return 80
        case .glassEnabled: return 81
        case .glassVibrancy: return 82
        case .glassChatList: return 83
        case .glassNavBars: return 84
        case .glassTabBar: return 85
        case .glassBubbles: return 86
        case .glassFooter: return 87
        case .spoofingHeader: return 100
        case .spoofPresetsHeader: return 101
        case let .spoofPreset(index, _, _, _, _): return 102 + Int32(index)
        case .spoofAddTemplate: return 203
        case .spoofDeleteSelected: return 204
        case .spoofingDevice: return 300
        case .spoofingDevicePreset: return 301
        case .spoofingWebviewPlatform: return 400
        case .spoofingApiId: return 401
        case .spoofingApiHash: return 402
        case .spoofingFooter: return 403
        case .expandableSelection(.sendWithoutSound, _, _, _): return 3
        case .expandableSelection(.peerId, _, _, _): return 52
        case .expandableSelection(.translationProvider, _, _, _): return 56
        case .expandableSelection(.webviewPlatform, _, _, _): return 400
        case .expandableSelection(.stashPrivacy, _, _, _): return 26
        }
    }

    static func <(lhs: WinterGramSettingsEntry, rhs: WinterGramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramSettingsArguments
        let lang = presentationData.strings
        switch self {
        case .banner:
            return WinterGramBannerItem(theme: presentationData.theme, title: "WinterGram", subtitle: "", iconImage: UIImage(bundleImageName: "WinterGramDark"), sectionId: self.section)
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_GHOSTMODE, sectionId: self.section)
        case let .ghostExpandable(value, isExpanded, subItems):
            return ItemListExpandableSwitchItem(presentationData: presentationData, systemStyle: .glass, title: lang.WinterGram_GhostMode, value: value, isExpanded: isExpanded, subItems: subItems, sectionId: self.section, style: .blocks, updated: { newValue in
                arguments.updateSettings { var s = $0; s.ghostModeEnabled = newValue; return s }
            }, selectAction: {
                arguments.toggleGhostExpanded()
            }, subAction: { subItem in
                guard let id = subItem.id as? String else {
                    return
                }
                arguments.updateSettings { settings in
                    var s = settings
                    switch id {
                    case "readMessages":
                        s.sendReadReceipts = !subItem.isSelected
                    case "readStories":
                        s.sendReadStories = !subItem.isSelected
                    case "online":
                        s.sendOnlineStatus = !subItem.isSelected
                    case "typing":
                        s.sendUploadProgress = !subItem.isSelected
                    case "autoOffline":
                        s.sendOfflineAfterOnline = subItem.isSelected
                    default:
                        break
                    }
                    s.ghostModeEnabled = true
                    return s
                }
            })
        case let .ghostSendWithoutSound(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_SendWithoutSound, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.toggleDropdown(.sendWithoutSound)
            })
        case let .ghostUseScheduledMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_UseScheduledMessages, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.useScheduledMessages = value; return s }
            })
        case let .ghostConfirmStory(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ConfirmStoryView, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.confirmStoryView = value; return s }
            })
        case let .ghostMarkReadAfterAction(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ReadAfterAction, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.markReadAfterAction = value; return s }
            })

        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_WhenGhostModeIsOnWinterGramStopsSendingReadReceiptsOnlineStatusAndTypingActivity), sectionId: self.section)

        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_HISTORY, sectionId: self.section)
        case .historyHeaderSpy:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_SPYMODE, sectionId: self.section)
        case let .historySaveDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_SaveDeletedMessages, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveDeletedMessages = value; return s }
            })
        case let .historySaveEdits(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_SaveEditHistory, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveMessagesHistory = value; return s }
            })
        case let .historySaveForBots(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_SaveDeletedFromBots, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveForBots = value; return s }
            })
        case let .historySaveSelfDestruct(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_SaveSelfDestructMessages, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.saveSelfDestructMessages = value; return s }
            })
        case let .historySemiTransparent(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_DimDeletedMessages, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.semiTransparentDeletedMessages = value; return s }
            })
        case let .historyDeletedMark(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_DeletedMark, label: value.isEmpty ? "🧹" : value, sectionId: self.section, style: .blocks, action: {
                arguments.editDeletedMark()
            })
        case let .historyShowDeletedTime(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ShowDeletionTime, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.showDeletedTime = value; return s }
            })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_DeletedAndEditedMessagesAreKeptLocallyOnThisDeviceOnly), sectionId: self.section)

        case .stashHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_HIDDENARCHIVE, sectionId: self.section)
        case let .stashList(count):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_StashedChats, label: count == 0 ? "" : "\(count)", sectionId: self.section, style: .blocks, action: {
                arguments.openStash()
            })
        case let .stashMute(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_MuteNotifications, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stashMuteNotifications = value; return s }
            })
        case let .stashAutoRead(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_AutoMarkAsRead, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stashAutoMarkRead = value; return s }
            })
        case let .stashPasscodeRow(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_StashPasscode, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.editStashPasscode()
            })
        case .stashFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_StashedChatsAreHiddenFromTheMainListAndAccessibleOnlyHere), sectionId: self.section)

        case .antiHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_FEATURES, sectionId: self.section)
        case let .antiDisableAds(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_DisableAds, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableAds = value; return s }
            })
        case let .antiLocalPremium(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_LocalPremium, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.localPremium = value; return s }
            })
        case let .antiDisableStories(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_HideStories, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableStories = value; return s }
            })
        case let .antiHidePremiumStatuses(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_HidePremiumStatuses, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.hidePremiumStatuses = value; return s }
            })
        case let .antiDisableLinkWarning(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_DisableOpenLinkWarning, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableOpenLinkWarning = value; return s }
            })
        case let .antiDisableCopyProtection(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_AllowSavingRestrictedContent, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.disableCopyProtection = value; return s }
            })
        case let .antiAllowScreenshots(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_AllowScreenshotsEverywhere, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.allowScreenshots = value; return s }
            })
        case .antiFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_LocalPremiumUnlocksPremiumOnlyUIOnThisDeviceItDoesNotGrantServerSidePremium), sectionId: self.section)

        case let .confirmStickers(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ConfirmStickers, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.stickerConfirmation = value; return s }
            })
        case let .confirmGif(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ConfirmGIFs, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.gifConfirmation = value; return s }
            })
        case let .confirmVoice(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ConfirmVoiceMessages, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.voiceConfirmation = value; return s }
            })

        case .chatHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_CHAT, sectionId: self.section)
        case let .chatPreview(theme, wallpaper, fontSize, chatBubbleCorners, strings, dateTimeFormat, nameDisplayOrder, messageItems):
            return ThemeSettingsChatPreviewItem(context: arguments.context, systemStyle: .glass, theme: theme, componentTheme: theme, strings: strings, sectionId: self.section, fontSize: fontSize, chatBubbleCorners: chatBubbleCorners, wallpaper: wallpaper, dateTimeFormat: dateTimeFormat, nameDisplayOrder: nameDisplayOrder, messageItems: messageItems)
        case let .chatShowPeerId(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_ShowPeerID, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.toggleDropdown(.peerId)
            })
        case let .chatShowRegistrationDate(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ShowRegistrationDate, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.showRegistrationDate = value; return s }
            })
        case let .chatHideEditedMark(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_HideEditedMark, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.hideEditedMark = value; return s }
            })
        case let .chatTranslateProvider(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_TranslationProvider, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.toggleDropdown(.translationProvider)
            })
        case let .chatWebviewHeight(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_IncreaseWebViewHeight, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.increaseWebviewHeight = value; return s }
            })
        case let .chatOnlyAddedEmoji(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_OnlyAddedEmojiStickers, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.showOnlyAddedEmojisAndStickers = value; return s }
            })
        case let .chatForwardWithoutAuthor(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ForwardWithoutAuthor, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.forwardWithoutAuthor = value; return s }
            })
        case .chatFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_TheseOptionsChangeHowMessageMetadataAndActionsAreShownInChats), sectionId: self.section)

        case .glassHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_LIQUIDGLASS, sectionId: self.section)
        case let .glassEnabled(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_LiquidGlass, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.enabled = value; return s }
            })
        case let .glassVibrancy(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_Vibrancy, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.vibrancy = value; return s }
            })
        case let .glassChatList(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ApplyToChatList, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToChatList = value; return s }
            })
        case let .glassNavBars(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ApplyToNavigationBars, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToNavigationBars = value; return s }
            })
        case let .glassTabBar(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ApplyToTabBar, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToTabBar = value; return s }
            })
        case let .glassBubbles(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_ApplyToBubbles, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.liquidGlass.applyToBubbles = value; return s }
            })
        case .glassFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_TransparencyBlurAndTintCanBeFineTunedPerSurfaceTurnLiquidGlassOffForTheStandardOpaqueLook), sectionId: self.section)

        case .spoofingHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_SPOOFING, sectionId: self.section)
        case let .spoofingDevice(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_SpoofDeviceModel, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.editSpoofDevice()
            })
        case let .spoofingDevicePreset(index, selected):
            let preset = winterGramDevicePresets[index]
            return ItemListCheckboxItem(presentationData: presentationData, title: preset.name, subtitle: preset.subtitle, style: .left, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { var s = $0; s.spoofDeviceModel = preset.model; return s }
            })
        case let .spoofingWebviewPlatform(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_WebViewPlatform, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.toggleDropdown(.webviewPlatform)
            })
        case let .spoofingApiId(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_APIID, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.editApiId()
            })
        case let .spoofingApiHash(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_APIHash, label: wntOption(value, lang), sectionId: self.section, style: .blocks, action: {
                arguments.editApiHash()
            })
        case .spoofPresetsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_Templates, sectionId: self.section)
        case let .spoofPreset(index, name, subtitle, editing, selected):
            if editing {
                return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: name, subtitle: subtitle, style: .left, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.toggleSpoofTemplateSelected(index)
                })
            } else {
                return ItemListDisclosureItem(presentationData: presentationData, title: name, label: subtitle, labelStyle: .detailText, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                    arguments.updateSettings { settings in
                        var settings = settings
                        if index < settings.spoofPresets.count {
                            let preset = settings.spoofPresets[index]
                            settings.spoofDeviceModel = preset.deviceModel.isEmpty ? nil : preset.deviceModel
                            settings.spoofAppVersion = preset.appVersion.isEmpty ? nil : preset.appVersion
                        }
                        return settings
                    }
                })
            }
        case .spoofAddTemplate:
            return ItemListPeerActionItem(presentationData: presentationData, icon: PresentationResourcesItemList.plusIconImage(presentationData.theme), title: lang.WinterGram_AddTemplate, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.addSpoofTemplate()
            })
        case .spoofDeleteSelected:
            return ItemListPeerActionItem(presentationData: presentationData, icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme), title: lang.WinterGram_DeleteSelected, sectionId: self.section, height: .generic, color: .destructive, editing: false, action: {
                arguments.deleteSelectedSpoofTemplates()
            })
        case .spoofingFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_SpoofTheDeviceModelAppVersionAndWebViewPlatformReportedToTelegramAndMiniAppsAPIIDHashUseYourOwnCredentialsFromMyTelegramOrgChangingThemRequiresReLogin), sectionId: self.section)
        case let .expandableSelection(dropdown, title, isExpanded, options):
            let mode: ItemListExpandableSelectionItem.SelectionMode = dropdown == .stashPrivacy ? .multiple : .single
            return ItemListExpandableSelectionItem(presentationData: presentationData, systemStyle: .glass, title: title, options: options, mode: mode, isExpanded: isExpanded, sectionId: self.section, style: .blocks, updated: { option in
                arguments.selectDropdownOption(dropdown, option.index)
            }, toggleExpanded: {
                arguments.toggleDropdown(dropdown)
            })
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

private func avatarRadiusLabel(_ value: Int32) -> String {
    switch value {
    case 50: return "Round"
    case 30: return "Squircle"
    case 15: return "Rounded"
    case 0: return "Square"
    default: return "\(value)"
    }
}

private func spoofLabel(_ value: String?) -> String {
    if let value = value, !value.isEmpty {
        return value
    }
    return "Default"
}

private func iconPackLabel(_ value: WinterGramIconPack) -> String {
    switch value {
    case .wintergram: return "WinterGram"
    case .ayugram: return "Ayu"
    case .exteragram: return "exteraGram"
    case .telegram: return "Telegram"
    }
}

private func winterGramSettingsEntries(presentationData: PresentationData, settings: WinterGramSettings, deletedCount: Int, expandedDropdown: WinterGramDropdown?, ghostExpanded: Bool, spoofTemplatesEditing: Bool, selectedTemplates: Set<Int>, category: WinterGramSettingsSection? = nil) -> [WinterGramSettingsEntry] {
    let lang = presentationData.strings
    var entries: [WinterGramSettingsEntry] = []

    // Appends an expandable single-select row with checkbox options shown inline.
    func appendDropdown(_ dropdown: WinterGramDropdown, _ title: String, _ section: WinterGramSettingsSection) {
        let options = winterGramDropdownOptions(dropdown, settings: settings).enumerated().map { index, option in
            ItemListExpandableSelectionItem.Option(id: "\(dropdown)_\(index)", title: wntOption(option.title, lang), isSelected: option.selected, index: index)
        }
        entries.append(.expandableSelection(dropdown, title, expandedDropdown == dropdown, options))
    }

    func appendGhost() {
        entries.append(.ghostHeader)
        // Expandable Ghost Mode switch with checkbox sub-items for each suppressed signal.
        let subItems: [ItemListExpandableSwitchItem.SubItem] = [
            .init(id: "readMessages", title: lang.WinterGram_DontReadMessages, isSelected: settings.suppressesReadReceipts, isEnabled: true),
            .init(id: "readStories", title: lang.WinterGram_DontReadStories, isSelected: settings.suppressesStoryViews, isEnabled: true),
            .init(id: "online", title: lang.WinterGram_DontSendOnline, isSelected: settings.suppressesOnlinePresence, isEnabled: true),
            .init(id: "typing", title: lang.WinterGram_DontSendTyping, isSelected: settings.suppressesTypingStatus, isEnabled: true),
            .init(id: "autoOffline", title: lang.WinterGram_AutoOffline, isSelected: settings.sendOfflineAfterOnline, isEnabled: true)
        ]
        entries.append(.ghostExpandable(settings.ghostModeEnabled, ghostExpanded, subItems))
        appendDropdown(.sendWithoutSound, lang.WinterGram_SendWithoutSound, .ghost)
        entries.append(.ghostUseScheduledMessages(settings.useScheduledMessages))
        entries.append(.ghostConfirmStory(settings.confirmStoryView))
        entries.append(.ghostMarkReadAfterAction(settings.markReadAfterAction))
        entries.append(.ghostFooter)
    }

    func appendHistory() {
        if category == .ayugram {
            entries.append(.historyHeaderSpy)
            entries.append(.historySaveDeleted(settings.saveDeletedMessages))
            entries.append(.historySaveEdits(settings.saveMessagesHistory))
            entries.append(.historyDeletedMark(settings.deletedMark))
            entries.append(.historyShowDeletedTime(settings.showDeletedTime))
        } else {
            entries.append(.historyHeader)
            entries.append(.historySaveDeleted(settings.saveDeletedMessages))
            entries.append(.historySaveEdits(settings.saveMessagesHistory))
            entries.append(.historySaveForBots(settings.saveForBots))
            entries.append(.historySaveSelfDestruct(settings.saveSelfDestructMessages))
            entries.append(.historySemiTransparent(settings.semiTransparentDeletedMessages))
            entries.append(.historyDeletedMark(settings.deletedMark))
            entries.append(.historyShowDeletedTime(settings.showDeletedTime))
            entries.append(.historyFooter)
        }
    }

    func appendStash() {
        entries.append(.stashHeader)
        entries.append(.stashList(Set(settings.stashedPeerIds).count))
        entries.append(.stashMute(settings.stashMuteNotifications))
        entries.append(.stashAutoRead(settings.stashAutoMarkRead))
        entries.append(.stashPasscodeRow(settings.stashPasscode.isEmpty ? "None" : "••••"))
        // All auto-privacy toggles combined into one expandable multi-select checkbox row.
        appendDropdown(.stashPrivacy, lang.WinterGram_AutoPrivacy, .stash)
        entries.append(.stashFooter)
    }

    func appendAntiFeatures() {
        entries.append(.antiHeader)
        entries.append(.antiDisableAds(settings.disableAds))
        entries.append(.antiLocalPremium(settings.localPremium))
        entries.append(.antiDisableStories(settings.disableStories))
        entries.append(.antiHidePremiumStatuses(settings.hidePremiumStatuses))
        entries.append(.antiDisableLinkWarning(settings.disableOpenLinkWarning))
        entries.append(.antiDisableCopyProtection(settings.disableCopyProtection))
        entries.append(.antiAllowScreenshots(settings.allowScreenshots))
        entries.append(.antiFooter)
    }

    func appendChat() {
        entries.append(.chatHeader)
        appendDropdown(.peerId, lang.WinterGram_ShowPeerID, .chat)
        entries.append(.chatShowRegistrationDate(settings.showRegistrationDate))
        entries.append(.chatHideEditedMark(settings.hideEditedMark))
        appendDropdown(.translationProvider, lang.WinterGram_MessageTranslation, .chat)
        entries.append(.chatWebviewHeight(settings.increaseWebviewHeight))
        entries.append(.chatOnlyAddedEmoji(settings.showOnlyAddedEmojisAndStickers))
        entries.append(.chatForwardWithoutAuthor(settings.forwardWithoutAuthor))
        entries.append(.confirmStickers(settings.stickerConfirmation))
        entries.append(.confirmGif(settings.gifConfirmation))
        entries.append(.confirmVoice(settings.voiceConfirmation))
        // Footer last (stableId 67) so the section stays in ascending stableId order.
        entries.append(.chatFooter)
    }

    func appendLiquidGlass() {
        entries.append(.glassHeader)
        entries.append(.glassEnabled(settings.liquidGlass.enabled))
        entries.append(.glassVibrancy(settings.liquidGlass.vibrancy))
        entries.append(.glassChatList(settings.liquidGlass.applyToChatList))
        entries.append(.glassNavBars(settings.liquidGlass.applyToNavigationBars))
        entries.append(.glassTabBar(settings.liquidGlass.applyToTabBar))
        entries.append(.glassBubbles(settings.liquidGlass.applyToBubbles))
        entries.append(.glassFooter)
    }

    func appendSpoofing() {
        entries.append(.spoofingHeader)
        // Saved spoof templates at the top of the Spoofing section.
        entries.append(.spoofPresetsHeader)
        for (index, preset) in settings.spoofPresets.enumerated() {
            let subtitle = [preset.deviceModel, preset.appVersion].filter { !$0.isEmpty }.joined(separator: " · ")
            entries.append(.spoofPreset(index, preset.name, subtitle.isEmpty ? "Default" : subtitle, spoofTemplatesEditing, selectedTemplates.contains(index)))
        }
        entries.append(.spoofAddTemplate)
        if spoofTemplatesEditing && !selectedTemplates.isEmpty {
            entries.append(.spoofDeleteSelected)
        }
        // Device model is chosen via the preset cards below (incl. "Real device") — no separate prompt row.
        for (i, preset) in winterGramDevicePresets.enumerated() {
            entries.append(.spoofingDevicePreset(i, preset.model == settings.spoofDeviceModel))
        }
        appendDropdown(.webviewPlatform, lang.WinterGram_WebViewPlatform, .spoofing)
        entries.append(.spoofingApiId(settings.customApiId.flatMap { $0 == 0 ? nil : "\($0)" } ?? "Default"))
        entries.append(.spoofingApiHash(spoofLabel(settings.customApiHash)))
        entries.append(.spoofingFooter)
    }

    if let category = category {
        switch category {
        case .banner:
            break
        case .ghost:
            appendGhost()
        case .history:
            appendHistory()
        case .stash:
            appendStash()
        case .antiFeatures:
            appendAntiFeatures()
        case .chat:
            appendChat()
        case .liquidGlass:
            appendLiquidGlass()
        case .spoofing:
            appendSpoofing()
        case .ayugram:
            appendGhost()
            appendHistory()
        case .other:
            appendChat()
        }
    } else {
        entries.append(.banner)
        appendGhost()
        appendHistory()
        appendStash()
        appendAntiFeatures()
        appendChat()
        appendLiquidGlass()
        appendSpoofing()
    }

    return entries
}

public func winterGramSettingsController(context: AccountContext, category: WinterGramSettingsSection? = nil) -> ViewController {
    let accountManager = context.sharedContext.accountManager

    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var refreshDeletedCount: (() -> Void)?

    // The combined super-categories (.ayugram/.other) are not standalone tabs in the legacy
    // no-category segmented view.
    let sectionTabs: [WinterGramSettingsSection] = WinterGramSettingsSection.allCases.filter { $0 != .ayugram && $0 != .other }
    let selectedCategoryPromise = ValuePromise<WinterGramSettingsSection>(category ?? .ghost, ignoreRepeated: true)

    let initialSettings = currentWinterGramSettings
    let requiresRestartPromise = ValuePromise<Bool>(false)

    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void = { f in
        let _ = (updateWinterGramSettingsInteractively(accountManager: accountManager, f)
        |> deliverOnMainQueue).startStandalone(next: { _ in
            let newSettings = currentWinterGramSettings
            let needsRestart = newSettings.spoofDeviceModel != initialSettings.spoofDeviceModel ||
                               newSettings.spoofAppVersion != initialSettings.spoofAppVersion ||
                               newSettings.customApiId != initialSettings.customApiId ||
                               newSettings.customApiHash != initialSettings.customApiHash ||
                               newSettings.materialDesign != initialSettings.materialDesign ||
                               newSettings.customFont != initialSettings.customFont ||
                               newSettings.monoFont != initialSettings.monoFont
            requiresRestartPromise.set(needsRestart)
        })
    }

    // Applies a change to the stashed-peer privacy settings and re-syncs exceptions for every
    // currently stashed peer when the rules change.
    let updateStashPrivacy: (@escaping (WinterGramStashPrivacySettings) -> WinterGramStashPrivacySettings) -> Void = { f in
        let previous = currentWinterGramSettings.stashPrivacy
        updateSettings { settings in
            var settings = settings
            settings.stashPrivacy = f(settings.stashPrivacy)
            return settings
        }
        let updated = f(previous)
        if updated != previous {
            for rawPeerId in Set(currentWinterGramSettings.stashedPeerIds) {
                let peerId = EnginePeer.Id(rawPeerId)
                let _ = winterGramApplyStashPrivacy(engine: context.engine, peerId: peerId, stashed: true, privacySettings: updated).startStandalone()
            }
        }
    }

    // Which inline dropdown (if any) is currently expanded. Atomic mirror for synchronous reads in the
    // toggle/select closures; promise drives the list rebuild.
    let expandedDropdownValue = Atomic<WinterGramDropdown?>(value: nil)
    let expandedDropdownPromise = ValuePromise<WinterGramDropdown?>(nil, ignoreRepeated: true)

    // Whether the Ghost Mode expandable section in the Core menu is open.
    let ghostExpandedValue = Atomic<Bool>(value: false)
    let ghostExpandedPromise = ValuePromise<Bool>(false, ignoreRepeated: true)
    let spoofTemplatesEditingValue = Atomic<Bool>(value: false)
    let spoofTemplatesEditingPromise = ValuePromise<Bool>(false, ignoreRepeated: true)
    let selectedTemplatesValue = Atomic<Set<Int>>(value: Set())
    let selectedTemplatesPromise = ValuePromise<Set<Int>>(Set(), ignoreRepeated: true)

    let arguments = WinterGramSettingsArguments(
        context: context,
        updateSettings: updateSettings,
        toggleDropdown: { dropdown in
            let newValue: WinterGramDropdown? = expandedDropdownValue.with { $0 == dropdown ? nil : dropdown }
            let _ = expandedDropdownValue.swap(newValue)
            expandedDropdownPromise.set(newValue)
        },
        selectDropdownOption: { dropdown, index in
            let options = winterGramDropdownOptions(dropdown, settings: currentWinterGramSettings)
            if index >= 0, index < options.count {
                if dropdown == .stashPrivacy {
                    updateStashPrivacy { privacy in
                        var settings = currentWinterGramSettings
                        settings.stashPrivacy = privacy
                        return options[index].apply(settings).stashPrivacy
                    }
                } else {
                    updateSettings { options[index].apply($0) }
                }
            }
            // Multi-select dropdowns stay open so the user can toggle more options.
            if dropdown != .stashPrivacy {
                let _ = expandedDropdownValue.swap(nil)
                expandedDropdownPromise.set(nil)
            }
        },
        toggleGhostExpanded: {
            let newValue = !ghostExpandedValue.with { $0 }
            let _ = ghostExpandedValue.swap(newValue)
            ghostExpandedPromise.set(newValue)
        },
        editSpoofDevice: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let lang = presentationData.strings
            let current = currentWinterGramSettings.spoofDeviceModel

            let controller = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []
            items.append(ActionSheetTextItem(title: lang.WinterGram_SpoofDeviceModel))

            let templates = [
                ("iPhone 16 Pro Max", "iPhone17,2", "11.1"),
                ("iPhone 15 Pro", "iPhone16,1", "11.1"),
                ("iPad Pro M4", "iPad16,3", "11.1"),
                ("Pixel 9 Pro", "Pixel 9 Pro", "11.1")
            ]

            for (name, model, version) in templates {
                items.append(ActionSheetButtonItem(title: name, action: { [weak controller] in
                    controller?.dismissAnimated()
                    updateSettings { var s = $0; s.spoofDeviceModel = model; s.spoofAppVersion = version; return s }
                }))
            }

            for preset in currentWinterGramSettings.spoofPresets {
                items.append(ActionSheetButtonItem(title: preset.name, action: { [weak controller] in
                    controller?.dismissAnimated()
                    updateSettings { var s = $0; s.spoofDeviceModel = preset.deviceModel; s.spoofAppVersion = preset.appVersion; return s }
                }))
            }

            items.append(ActionSheetButtonItem(title: lang.WinterGram_Custom, action: { [weak controller] in
                controller?.dismissAnimated()
                let prompt = promptController(context: context, text: lang.WinterGram_SpoofDeviceModel, value: current, placeholder: current ?? "iPhone17,2", characterLimit: 64, apply: { value in
                    updateSettings { var s = $0; s.spoofDeviceModel = (value?.isEmpty ?? true) ? nil : value; return s }
                })
                presentControllerImpl?(prompt, nil)
            }))

            items.append(ActionSheetButtonItem(title: lang.WinterGram_SaveCurrentAsProfile, color: .accent, action: { [weak controller] in
                controller?.dismissAnimated()
                let prompt = promptController(context: context, text: lang.WinterGram_ProfileName, value: nil, placeholder: "My Profile", characterLimit: 32, apply: { name in
                    if let name = name, !name.isEmpty {
                        updateSettings { var s = $0
                            let preset = WinterGramSpoofPreset(name: name, deviceModel: s.spoofDeviceModel ?? "", appVersion: s.spoofAppVersion ?? "")
                            s.spoofPresets.append(preset)
                            return s
                        }
                    }
                })
                presentControllerImpl?(prompt, nil)
            }))

            items.append(ActionSheetButtonItem(title: lang.WinterGram_DefaultRealDevice, color: .destructive, action: { [weak controller] in
                controller?.dismissAnimated()
                updateSettings { var s = $0; s.spoofDeviceModel = nil; s.spoofAppVersion = nil; return s }
            }))

            controller.setItemGroups([
                ActionSheetItemGroup(items: items),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak controller] in
                        controller?.dismissAnimated()
                    })
                ])
            ])
            presentControllerImpl?(controller, nil)
        },
        addSpoofTemplate: {
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
            let controller = promptController(context: context, text: lang.WinterGram_ProfileName, value: nil, placeholder: "My Profile", characterLimit: 32, apply: { name in
                if let name = name?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
                    updateSettings { settings in
                        var settings = settings
                        settings.spoofPresets.append(WinterGramSpoofPreset(name: name, deviceModel: settings.spoofDeviceModel ?? "", appVersion: settings.spoofAppVersion ?? ""))
                        return settings
                    }
                }
            })
            presentControllerImpl?(controller, nil)
        },
        toggleSpoofTemplateSelected: { index in
            let updated = selectedTemplatesValue.modify { selected in
                var selected = selected
                if selected.contains(index) {
                    selected.remove(index)
                } else {
                    selected.insert(index)
                }
                return selected
            }
            selectedTemplatesPromise.set(updated)
        },
        deleteSelectedSpoofTemplates: {
            let selected = selectedTemplatesValue.with { $0 }
            guard !selected.isEmpty else { return }
            updateSettings { settings in
                var settings = settings
                let sorted = selected.sorted(by: >)
                for index in sorted {
                    if index >= 0 && index < settings.spoofPresets.count {
                        settings.spoofPresets.remove(at: index)
                    }
                }
                return settings
            }
            let _ = selectedTemplatesValue.swap(Set())
            selectedTemplatesPromise.set(Set())
        },
        editApiId: {
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
            let current = currentWinterGramSettings.customApiId.flatMap { $0 == 0 ? nil : "\($0)" }
            let controller = promptController(context: context, text: lang.WinterGram_APIID, value: current, placeholder: "1234567", characterLimit: 16, apply: { value in
                updateSettings { var s = $0
                    if let value = value, let parsed = Int32(value.trimmingCharacters(in: .whitespaces)), parsed != 0 {
                        s.customApiId = parsed
                    } else {
                        s.customApiId = nil
                    }
                    return s
                }
            })
            presentControllerImpl?(controller, nil)
        },
        editApiHash: {
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
            let current = currentWinterGramSettings.customApiHash
            let controller = promptController(context: context, text: lang.WinterGram_APIHash, value: current, placeholder: "0123456789abcdef0123456789abcdef", characterLimit: 64, apply: { value in
                updateSettings { var s = $0
                    let trimmed = value?.trimmingCharacters(in: .whitespaces)
                    s.customApiHash = (trimmed?.isEmpty ?? true) ? nil : trimmed
                    return s
                }
            })
            presentControllerImpl?(controller, nil)
        },
        openStash: {
            let passcode = currentWinterGramSettings.stashPasscode
            if passcode.isEmpty {
                pushControllerImpl?(winterGramStashController(context: context))
            } else {
                let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
                let controller = promptController(context: context, text: lang.WinterGram_EnterPasscode, value: nil, placeholder: "••••", characterLimit: 16, apply: { value in
                    if (value ?? "") == passcode {
                        pushControllerImpl?(winterGramStashController(context: context))
                    }
                })
                presentControllerImpl?(controller, nil)
            }
        },
        editStashPasscode: {
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
            let current = currentWinterGramSettings.stashPasscode
            let controller = promptController(context: context, text: lang.WinterGram_StashPasscode, value: current.isEmpty ? nil : current, placeholder: lang.WinterGram_EmptyNoPasscode, characterLimit: 16, apply: { value in
                updateSettings { var s = $0; s.stashPasscode = (value ?? "").trimmingCharacters(in: .whitespaces); return s }
            })
            presentControllerImpl?(controller, nil)
        },
        editDeletedMark: {
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings
            let current = currentWinterGramSettings.deletedMark
            let controller = promptController(context: context, text: lang.WinterGram_DeletedMark, value: current.isEmpty ? nil : current, placeholder: "🧹", characterLimit: 8, apply: { value in
                updateSettings { var s = $0; s.deletedMark = (value ?? "").trimmingCharacters(in: .whitespaces); return s }
            })
            presentControllerImpl?(controller, nil)
        },
        openUrl: { url in
            context.sharedContext.applicationBindings.openUrl(url)
        },
        clearDeleted: {
            let _ = (winterGramClearDeletedMessages(postbox: context.account.postbox)
            |> deliverOnMainQueue).startStandalone(next: { _ in
                refreshDeletedCount?()
            })
        }
    )

    let deletedCountPromise = Promise<Int>()
    deletedCountPromise.set(winterGramDeletedMessagesCount(postbox: context.account.postbox))
    refreshDeletedCount = {
        deletedCountPromise.set(winterGramDeletedMessagesCount(postbox: context.account.postbox))
    }

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        winterGramSettings(accountManager: accountManager),
        deletedCountPromise.get(),
        selectedCategoryPromise.get(),
        expandedDropdownPromise.get(),
        ghostExpandedPromise.get(),
        spoofTemplatesEditingPromise.get(),
        selectedTemplatesPromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings, deletedCount, selectedCategory, expandedDropdown, ghostExpanded, spoofTemplatesEditing, selectedTemplates -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let lang = presentationData.strings
        let controllerState: ItemListControllerState
        if let category = category {
            let controllerStateTitle = wntOption(category.title, presentationData.strings)
            let rightNavigationButton: ItemListNavigationButton?
            if category == .spoofing, !settings.spoofPresets.isEmpty {
                rightNavigationButton = ItemListNavigationButton(content: .text(spoofTemplatesEditing ? presentationData.strings.Common_Done : presentationData.strings.Common_Edit), style: spoofTemplatesEditing ? .bold : .regular, enabled: true, action: {
                    let nextValue = !spoofTemplatesEditingValue.with { $0 }
                    let _ = spoofTemplatesEditingValue.swap(nextValue)
                    if !nextValue {
                        let _ = selectedTemplatesValue.swap(Set())
                        selectedTemplatesPromise.set(Set())
                    }
                    spoofTemplatesEditingPromise.set(nextValue)
                })
            } else {
                rightNavigationButton = nil
            }
            controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(controllerStateTitle), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        } else {
            let titles = sectionTabs.map { wntOption($0.title, lang) }
            let selectedIndex = sectionTabs.firstIndex(of: selectedCategory) ?? 0
            controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .sectionControl(titles, selectedIndex), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        }
        let activeCategory = category ?? selectedCategory
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: winterGramSettingsEntries(presentationData: presentationData, settings: settings, deletedCount: deletedCount, expandedDropdown: expandedDropdown, ghostExpanded: ghostExpanded, spoofTemplatesEditing: spoofTemplatesEditing, selectedTemplates: selectedTemplates, category: activeCategory), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.titleControlValueChanged = { index in
        selectedCategoryPromise.set(sectionTabs[index])
    }

    var bannerController: UndoOverlayController?
    let restartBannerDisposable = (requiresRestartPromise.get()
    |> deliverOnMainQueue).start(next: { [weak controller] needsRestart in
        guard let controller = controller else { return }
        if needsRestart {
            if bannerController == nil {
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                let banner = UndoOverlayController(presentationData: presentationData, content: .info(title: presentationData.strings.WinterGram_RestartRequired, text: presentationData.strings.WinterGram_SomeSettingsWillTakeEffectAfterRestart, timeout: nil, customUndoText: presentationData.strings.WinterGram_Restart), elevatedLayout: false, action: { action in
                    if action == .undo {
                        exit(0)
                    }
                    return true
                })
                bannerController = banner
                controller.present(banner, in: .window(.root))
            }
        } else {
            bannerController?.dismiss()
            bannerController = nil
        }
    })

    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        // Keep the restart-banner subscription alive for the controller's lifetime: this
        // closure is retained by `arguments`, which the ItemListController holds via its state.
        let _ = restartBannerDisposable
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
