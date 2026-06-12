import Foundation
import TelegramCore
import SwiftSignalKit

public enum WinterGramSendWithoutSound: Int32, Codable {
    case never = 0
    case inGhostMode = 1
    case always = 2
}

public enum WinterGramPeerIdDisplay: Int32, Codable {
    case hidden = 0
    case telegramApi = 1
    case botApi = 2
}

public enum WinterGramTranslationProvider: Int32, Codable {
    case telegram = 0
    case google = 1
    case yandex = 2
    case system = 3
}

public enum WinterGramWebviewPlatform: Int32, Codable {
    case auto = 0
    case ios = 1
    case android = 2
    case macos = 3
    case desktop = 4
}

public enum WinterGramIconPack: Int32, Codable {
    case wintergram = 0
    case ayugram = 1
    case exteragram = 2
    case telegram = 3
}

public struct WinterGramLiquidGlass: Codable, Equatable {
    public var enabled: Bool
    public var transparency: Double
    public var blurRadius: Double
    public var tintColor: Int32?
    public var vibrancy: Bool
    public var applyToChatList: Bool
    public var applyToBubbles: Bool
    public var applyToNavigationBars: Bool
    public var applyToTabBar: Bool

    public static var defaultSettings: WinterGramLiquidGlass {
        return WinterGramLiquidGlass(
            enabled: true,
            transparency: 0.75,
            blurRadius: 30.0,
            tintColor: nil,
            vibrancy: true,
            applyToChatList: true,
            applyToBubbles: false,
            applyToNavigationBars: true,
            applyToTabBar: true
        )
    }

    public init(
        enabled: Bool,
        transparency: Double,
        blurRadius: Double,
        tintColor: Int32?,
        vibrancy: Bool,
        applyToChatList: Bool,
        applyToBubbles: Bool,
        applyToNavigationBars: Bool,
        applyToTabBar: Bool
    ) {
        self.enabled = enabled
        self.transparency = transparency
        self.blurRadius = blurRadius
        self.tintColor = tintColor
        self.vibrancy = vibrancy
        self.applyToChatList = applyToChatList
        self.applyToBubbles = applyToBubbles
        self.applyToNavigationBars = applyToNavigationBars
        self.applyToTabBar = applyToTabBar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: "enabled") ?? true
        self.transparency = try container.decodeIfPresent(Double.self, forKey: "transparency") ?? 0.75
        self.blurRadius = try container.decodeIfPresent(Double.self, forKey: "blurRadius") ?? 30.0
        self.tintColor = try container.decodeIfPresent(Int32.self, forKey: "tintColor")
        self.vibrancy = try container.decodeIfPresent(Bool.self, forKey: "vibrancy") ?? true
        self.applyToChatList = try container.decodeIfPresent(Bool.self, forKey: "applyToChatList") ?? true
        self.applyToBubbles = try container.decodeIfPresent(Bool.self, forKey: "applyToBubbles") ?? false
        self.applyToNavigationBars = try container.decodeIfPresent(Bool.self, forKey: "applyToNavigationBars") ?? true
        self.applyToTabBar = try container.decodeIfPresent(Bool.self, forKey: "applyToTabBar") ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.enabled, forKey: "enabled")
        try container.encode(self.transparency, forKey: "transparency")
        try container.encode(self.blurRadius, forKey: "blurRadius")
        try container.encodeIfPresent(self.tintColor, forKey: "tintColor")
        try container.encode(self.vibrancy, forKey: "vibrancy")
        try container.encode(self.applyToChatList, forKey: "applyToChatList")
        try container.encode(self.applyToBubbles, forKey: "applyToBubbles")
        try container.encode(self.applyToNavigationBars, forKey: "applyToNavigationBars")
        try container.encode(self.applyToTabBar, forKey: "applyToTabBar")
    }
}

public struct WinterGramSettings: Codable, Equatable {
    // Ghost mode & privacy
    public var ghostModeEnabled: Bool
    public var sendReadReceipts: Bool
    public var sendReadStories: Bool
    public var sendOnlineStatus: Bool
    public var sendUploadProgress: Bool
    public var sendOfflineAfterOnline: Bool
    public var markReadAfterAction: Bool
    public var useScheduledMessages: Bool
    public var sendWithoutSound: WinterGramSendWithoutSound
    public var suggestGhostBeforeStory: Bool

    // Local history
    public var saveDeletedMessages: Bool
    public var saveMessagesHistory: Bool
    public var saveForBots: Bool
    public var hideFromBlocked: Bool
    public var semiTransparentDeletedMessages: Bool

    // Hidden archive ("ААрхив")
    public var stashedPeerIds: [Int64]
    public var stashMuteNotifications: Bool
    public var stashAutoMarkRead: Bool

    // Anti-features
    public var disableAds: Bool
    public var localPremium: Bool
    public var shadowBanIds: [Int64]
    public var disableStories: Bool
    public var hidePremiumStatuses: Bool
    public var disableOpenLinkWarning: Bool

    // Confirmations
    public var stickerConfirmation: Bool
    public var gifConfirmation: Bool
    public var voiceConfirmation: Bool

    // Message decorations
    public var showMessageSeconds: Bool
    public var showPeerId: WinterGramPeerIdDisplay
    public var deletedMark: String
    public var editedMark: String
    public var recentStickersCount: Int32

    // Translation
    public var translateMessages: Bool
    public var translationProvider: WinterGramTranslationProvider

    // Webview / platform spoofing
    public var webviewSpoofPlatform: WinterGramWebviewPlatform
    public var increaseWebviewHeight: Bool

    // Appearance & customization
    public var liquidGlass: WinterGramLiquidGlass
    public var materialDesign: Bool
    public var avatarCornerRadius: Int32
    public var singleCornerRadius: Bool
    public var messageBubbleRadius: Int32
    public var removeMessageTail: Bool
    public var customFont: String?
    public var monoFont: String?
    public var appIcon: String
    public var iconPack: WinterGramIconPack
    public var showOnlyAddedEmojisAndStickers: Bool

    public static var defaultSettings: WinterGramSettings {
        return WinterGramSettings(
            ghostModeEnabled: false,
            sendReadReceipts: true,
            sendReadStories: true,
            sendOnlineStatus: true,
            sendUploadProgress: true,
            sendOfflineAfterOnline: false,
            markReadAfterAction: true,
            useScheduledMessages: false,
            sendWithoutSound: .never,
            suggestGhostBeforeStory: true,
            saveDeletedMessages: true,
            saveMessagesHistory: true,
            saveForBots: false,
            hideFromBlocked: false,
            semiTransparentDeletedMessages: false,
            stashedPeerIds: [],
            stashMuteNotifications: true,
            stashAutoMarkRead: false,
            disableAds: true,
            localPremium: false,
            shadowBanIds: [],
            disableStories: false,
            hidePremiumStatuses: false,
            disableOpenLinkWarning: false,
            stickerConfirmation: false,
            gifConfirmation: false,
            voiceConfirmation: false,
            showMessageSeconds: false,
            showPeerId: .botApi,
            deletedMark: "🧹",
            editedMark: "",
            recentStickersCount: 100,
            translateMessages: false,
            translationProvider: .telegram,
            webviewSpoofPlatform: .auto,
            increaseWebviewHeight: false,
            liquidGlass: .defaultSettings,
            materialDesign: true,
            avatarCornerRadius: 50,
            singleCornerRadius: false,
            messageBubbleRadius: 16,
            removeMessageTail: false,
            customFont: nil,
            monoFont: nil,
            appIcon: "WinterGramDark",
            iconPack: .wintergram,
            showOnlyAddedEmojisAndStickers: false
        )
    }

    public init(
        ghostModeEnabled: Bool,
        sendReadReceipts: Bool,
        sendReadStories: Bool,
        sendOnlineStatus: Bool,
        sendUploadProgress: Bool,
        sendOfflineAfterOnline: Bool,
        markReadAfterAction: Bool,
        useScheduledMessages: Bool,
        sendWithoutSound: WinterGramSendWithoutSound,
        suggestGhostBeforeStory: Bool,
        saveDeletedMessages: Bool,
        saveMessagesHistory: Bool,
        saveForBots: Bool,
        hideFromBlocked: Bool,
        semiTransparentDeletedMessages: Bool,
        stashedPeerIds: [Int64],
        stashMuteNotifications: Bool,
        stashAutoMarkRead: Bool,
        disableAds: Bool,
        localPremium: Bool,
        shadowBanIds: [Int64],
        disableStories: Bool,
        hidePremiumStatuses: Bool,
        disableOpenLinkWarning: Bool,
        stickerConfirmation: Bool,
        gifConfirmation: Bool,
        voiceConfirmation: Bool,
        showMessageSeconds: Bool,
        showPeerId: WinterGramPeerIdDisplay,
        deletedMark: String,
        editedMark: String,
        recentStickersCount: Int32,
        translateMessages: Bool,
        translationProvider: WinterGramTranslationProvider,
        webviewSpoofPlatform: WinterGramWebviewPlatform,
        increaseWebviewHeight: Bool,
        liquidGlass: WinterGramLiquidGlass,
        materialDesign: Bool,
        avatarCornerRadius: Int32,
        singleCornerRadius: Bool,
        messageBubbleRadius: Int32,
        removeMessageTail: Bool,
        customFont: String?,
        monoFont: String?,
        appIcon: String,
        iconPack: WinterGramIconPack,
        showOnlyAddedEmojisAndStickers: Bool
    ) {
        self.ghostModeEnabled = ghostModeEnabled
        self.sendReadReceipts = sendReadReceipts
        self.sendReadStories = sendReadStories
        self.sendOnlineStatus = sendOnlineStatus
        self.sendUploadProgress = sendUploadProgress
        self.sendOfflineAfterOnline = sendOfflineAfterOnline
        self.markReadAfterAction = markReadAfterAction
        self.useScheduledMessages = useScheduledMessages
        self.sendWithoutSound = sendWithoutSound
        self.suggestGhostBeforeStory = suggestGhostBeforeStory
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessagesHistory = saveMessagesHistory
        self.saveForBots = saveForBots
        self.hideFromBlocked = hideFromBlocked
        self.semiTransparentDeletedMessages = semiTransparentDeletedMessages
        self.stashedPeerIds = stashedPeerIds
        self.stashMuteNotifications = stashMuteNotifications
        self.stashAutoMarkRead = stashAutoMarkRead
        self.disableAds = disableAds
        self.localPremium = localPremium
        self.shadowBanIds = shadowBanIds
        self.disableStories = disableStories
        self.hidePremiumStatuses = hidePremiumStatuses
        self.disableOpenLinkWarning = disableOpenLinkWarning
        self.stickerConfirmation = stickerConfirmation
        self.gifConfirmation = gifConfirmation
        self.voiceConfirmation = voiceConfirmation
        self.showMessageSeconds = showMessageSeconds
        self.showPeerId = showPeerId
        self.deletedMark = deletedMark
        self.editedMark = editedMark
        self.recentStickersCount = recentStickersCount
        self.translateMessages = translateMessages
        self.translationProvider = translationProvider
        self.webviewSpoofPlatform = webviewSpoofPlatform
        self.increaseWebviewHeight = increaseWebviewHeight
        self.liquidGlass = liquidGlass
        self.materialDesign = materialDesign
        self.avatarCornerRadius = avatarCornerRadius
        self.singleCornerRadius = singleCornerRadius
        self.messageBubbleRadius = messageBubbleRadius
        self.removeMessageTail = removeMessageTail
        self.customFont = customFont
        self.monoFont = monoFont
        self.appIcon = appIcon
        self.iconPack = iconPack
        self.showOnlyAddedEmojisAndStickers = showOnlyAddedEmojisAndStickers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        let defaults = WinterGramSettings.defaultSettings

        self.ghostModeEnabled = try container.decodeIfPresent(Bool.self, forKey: "ghostModeEnabled") ?? defaults.ghostModeEnabled
        self.sendReadReceipts = try container.decodeIfPresent(Bool.self, forKey: "sendReadReceipts") ?? defaults.sendReadReceipts
        self.sendReadStories = try container.decodeIfPresent(Bool.self, forKey: "sendReadStories") ?? defaults.sendReadStories
        self.sendOnlineStatus = try container.decodeIfPresent(Bool.self, forKey: "sendOnlineStatus") ?? defaults.sendOnlineStatus
        self.sendUploadProgress = try container.decodeIfPresent(Bool.self, forKey: "sendUploadProgress") ?? defaults.sendUploadProgress
        self.sendOfflineAfterOnline = try container.decodeIfPresent(Bool.self, forKey: "sendOfflineAfterOnline") ?? defaults.sendOfflineAfterOnline
        self.markReadAfterAction = try container.decodeIfPresent(Bool.self, forKey: "markReadAfterAction") ?? defaults.markReadAfterAction
        self.useScheduledMessages = try container.decodeIfPresent(Bool.self, forKey: "useScheduledMessages") ?? defaults.useScheduledMessages
        self.sendWithoutSound = try container.decodeIfPresent(WinterGramSendWithoutSound.self, forKey: "sendWithoutSound") ?? defaults.sendWithoutSound
        self.suggestGhostBeforeStory = try container.decodeIfPresent(Bool.self, forKey: "suggestGhostBeforeStory") ?? defaults.suggestGhostBeforeStory
        self.saveDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "saveDeletedMessages") ?? defaults.saveDeletedMessages
        self.saveMessagesHistory = try container.decodeIfPresent(Bool.self, forKey: "saveMessagesHistory") ?? defaults.saveMessagesHistory
        self.saveForBots = try container.decodeIfPresent(Bool.self, forKey: "saveForBots") ?? defaults.saveForBots
        self.hideFromBlocked = try container.decodeIfPresent(Bool.self, forKey: "hideFromBlocked") ?? defaults.hideFromBlocked
        self.semiTransparentDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "semiTransparentDeletedMessages") ?? defaults.semiTransparentDeletedMessages
        self.stashedPeerIds = try container.decodeIfPresent([Int64].self, forKey: "stashedPeerIds") ?? defaults.stashedPeerIds
        self.stashMuteNotifications = try container.decodeIfPresent(Bool.self, forKey: "stashMuteNotifications") ?? defaults.stashMuteNotifications
        self.stashAutoMarkRead = try container.decodeIfPresent(Bool.self, forKey: "stashAutoMarkRead") ?? defaults.stashAutoMarkRead
        self.disableAds = try container.decodeIfPresent(Bool.self, forKey: "disableAds") ?? defaults.disableAds
        self.localPremium = try container.decodeIfPresent(Bool.self, forKey: "localPremium") ?? defaults.localPremium
        self.shadowBanIds = try container.decodeIfPresent([Int64].self, forKey: "shadowBanIds") ?? defaults.shadowBanIds
        self.disableStories = try container.decodeIfPresent(Bool.self, forKey: "disableStories") ?? defaults.disableStories
        self.hidePremiumStatuses = try container.decodeIfPresent(Bool.self, forKey: "hidePremiumStatuses") ?? defaults.hidePremiumStatuses
        self.disableOpenLinkWarning = try container.decodeIfPresent(Bool.self, forKey: "disableOpenLinkWarning") ?? defaults.disableOpenLinkWarning
        self.stickerConfirmation = try container.decodeIfPresent(Bool.self, forKey: "stickerConfirmation") ?? defaults.stickerConfirmation
        self.gifConfirmation = try container.decodeIfPresent(Bool.self, forKey: "gifConfirmation") ?? defaults.gifConfirmation
        self.voiceConfirmation = try container.decodeIfPresent(Bool.self, forKey: "voiceConfirmation") ?? defaults.voiceConfirmation
        self.showMessageSeconds = try container.decodeIfPresent(Bool.self, forKey: "showMessageSeconds") ?? defaults.showMessageSeconds
        self.showPeerId = try container.decodeIfPresent(WinterGramPeerIdDisplay.self, forKey: "showPeerId") ?? defaults.showPeerId
        self.deletedMark = try container.decodeIfPresent(String.self, forKey: "deletedMark") ?? defaults.deletedMark
        self.editedMark = try container.decodeIfPresent(String.self, forKey: "editedMark") ?? defaults.editedMark
        self.recentStickersCount = try container.decodeIfPresent(Int32.self, forKey: "recentStickersCount") ?? defaults.recentStickersCount
        self.translateMessages = try container.decodeIfPresent(Bool.self, forKey: "translateMessages") ?? defaults.translateMessages
        self.translationProvider = try container.decodeIfPresent(WinterGramTranslationProvider.self, forKey: "translationProvider") ?? defaults.translationProvider
        self.webviewSpoofPlatform = try container.decodeIfPresent(WinterGramWebviewPlatform.self, forKey: "webviewSpoofPlatform") ?? defaults.webviewSpoofPlatform
        self.increaseWebviewHeight = try container.decodeIfPresent(Bool.self, forKey: "increaseWebviewHeight") ?? defaults.increaseWebviewHeight
        self.liquidGlass = try container.decodeIfPresent(WinterGramLiquidGlass.self, forKey: "liquidGlass") ?? defaults.liquidGlass
        self.materialDesign = try container.decodeIfPresent(Bool.self, forKey: "materialDesign") ?? defaults.materialDesign
        self.avatarCornerRadius = try container.decodeIfPresent(Int32.self, forKey: "avatarCornerRadius") ?? defaults.avatarCornerRadius
        self.singleCornerRadius = try container.decodeIfPresent(Bool.self, forKey: "singleCornerRadius") ?? defaults.singleCornerRadius
        self.messageBubbleRadius = try container.decodeIfPresent(Int32.self, forKey: "messageBubbleRadius") ?? defaults.messageBubbleRadius
        self.removeMessageTail = try container.decodeIfPresent(Bool.self, forKey: "removeMessageTail") ?? defaults.removeMessageTail
        self.customFont = try container.decodeIfPresent(String.self, forKey: "customFont")
        self.monoFont = try container.decodeIfPresent(String.self, forKey: "monoFont")
        self.appIcon = try container.decodeIfPresent(String.self, forKey: "appIcon") ?? defaults.appIcon
        self.iconPack = try container.decodeIfPresent(WinterGramIconPack.self, forKey: "iconPack") ?? defaults.iconPack
        self.showOnlyAddedEmojisAndStickers = try container.decodeIfPresent(Bool.self, forKey: "showOnlyAddedEmojisAndStickers") ?? defaults.showOnlyAddedEmojisAndStickers
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.ghostModeEnabled, forKey: "ghostModeEnabled")
        try container.encode(self.sendReadReceipts, forKey: "sendReadReceipts")
        try container.encode(self.sendReadStories, forKey: "sendReadStories")
        try container.encode(self.sendOnlineStatus, forKey: "sendOnlineStatus")
        try container.encode(self.sendUploadProgress, forKey: "sendUploadProgress")
        try container.encode(self.sendOfflineAfterOnline, forKey: "sendOfflineAfterOnline")
        try container.encode(self.markReadAfterAction, forKey: "markReadAfterAction")
        try container.encode(self.useScheduledMessages, forKey: "useScheduledMessages")
        try container.encode(self.sendWithoutSound, forKey: "sendWithoutSound")
        try container.encode(self.suggestGhostBeforeStory, forKey: "suggestGhostBeforeStory")
        try container.encode(self.saveDeletedMessages, forKey: "saveDeletedMessages")
        try container.encode(self.saveMessagesHistory, forKey: "saveMessagesHistory")
        try container.encode(self.saveForBots, forKey: "saveForBots")
        try container.encode(self.hideFromBlocked, forKey: "hideFromBlocked")
        try container.encode(self.semiTransparentDeletedMessages, forKey: "semiTransparentDeletedMessages")
        try container.encode(self.stashedPeerIds, forKey: "stashedPeerIds")
        try container.encode(self.stashMuteNotifications, forKey: "stashMuteNotifications")
        try container.encode(self.stashAutoMarkRead, forKey: "stashAutoMarkRead")
        try container.encode(self.disableAds, forKey: "disableAds")
        try container.encode(self.localPremium, forKey: "localPremium")
        try container.encode(self.shadowBanIds, forKey: "shadowBanIds")
        try container.encode(self.disableStories, forKey: "disableStories")
        try container.encode(self.hidePremiumStatuses, forKey: "hidePremiumStatuses")
        try container.encode(self.disableOpenLinkWarning, forKey: "disableOpenLinkWarning")
        try container.encode(self.stickerConfirmation, forKey: "stickerConfirmation")
        try container.encode(self.gifConfirmation, forKey: "gifConfirmation")
        try container.encode(self.voiceConfirmation, forKey: "voiceConfirmation")
        try container.encode(self.showMessageSeconds, forKey: "showMessageSeconds")
        try container.encode(self.showPeerId, forKey: "showPeerId")
        try container.encode(self.deletedMark, forKey: "deletedMark")
        try container.encode(self.editedMark, forKey: "editedMark")
        try container.encode(self.recentStickersCount, forKey: "recentStickersCount")
        try container.encode(self.translateMessages, forKey: "translateMessages")
        try container.encode(self.translationProvider, forKey: "translationProvider")
        try container.encode(self.webviewSpoofPlatform, forKey: "webviewSpoofPlatform")
        try container.encode(self.increaseWebviewHeight, forKey: "increaseWebviewHeight")
        try container.encode(self.liquidGlass, forKey: "liquidGlass")
        try container.encode(self.materialDesign, forKey: "materialDesign")
        try container.encode(self.avatarCornerRadius, forKey: "avatarCornerRadius")
        try container.encode(self.singleCornerRadius, forKey: "singleCornerRadius")
        try container.encode(self.messageBubbleRadius, forKey: "messageBubbleRadius")
        try container.encode(self.removeMessageTail, forKey: "removeMessageTail")
        try container.encodeIfPresent(self.customFont, forKey: "customFont")
        try container.encodeIfPresent(self.monoFont, forKey: "monoFont")
        try container.encode(self.appIcon, forKey: "appIcon")
        try container.encode(self.iconPack, forKey: "iconPack")
        try container.encode(self.showOnlyAddedEmojisAndStickers, forKey: "showOnlyAddedEmojisAndStickers")
    }

    public func isShadowBanned(_ peerId: Int64) -> Bool {
        return self.shadowBanIds.contains(peerId)
    }

    public func isStashed(_ peerId: Int64) -> Bool {
        return self.stashedPeerIds.contains(peerId)
    }

    public var shouldSendWithoutSound: Bool {
        switch self.sendWithoutSound {
        case .never:
            return false
        case .inGhostMode:
            return self.ghostModeEnabled
        case .always:
            return true
        }
    }
}

public func updateWinterGramSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (WinterGramSettings) -> WinterGramSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.winterGramSettings, { entry in
            let currentSettings: WinterGramSettings
            if let entry = entry?.get(WinterGramSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}

public func winterGramSettings(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<WinterGramSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.winterGramSettings])
    |> map { sharedData -> WinterGramSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.winterGramSettings]?.get(WinterGramSettings.self) ?? .defaultSettings
    }
}

private let currentWinterGramSettingsValue = Atomic<WinterGramSettings>(value: .defaultSettings)

// Synchronous snapshot of the latest settings, for hook points that cannot subscribe to a Signal.
// Kept up to date by observeWinterGramSettings(accountManager:) at app startup.
public var currentWinterGramSettings: WinterGramSettings {
    return currentWinterGramSettingsValue.with { $0 }
}

public func setCurrentWinterGramSettings(_ settings: WinterGramSettings) {
    let _ = currentWinterGramSettingsValue.swap(settings)
}

public func observeWinterGramSettings(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Disposable {
    return (winterGramSettings(accountManager: accountManager)
    |> deliverOnMainQueue).start(next: { settings in
        setCurrentWinterGramSettings(settings)
    })
}
