import Foundation
import TelegramCore
import SwiftSignalKit

public enum WinterGramSendWithoutSound: Int32 {
    case never = 0
    case inGhostMode = 1
    case always = 2
}

public enum WinterGramPeerIdDisplay: Int32 {
    case hidden = 0
    case telegramApi = 1
    case botApi = 2
}

public enum WinterGramTranslationProvider: Int32 {
    case telegram = 0
    case google = 1
    case yandex = 2
    case system = 3
}

public enum WinterGramWebviewPlatform: Int32 {
    case auto = 0
    case ios = 1
    case android = 2
    case macos = 3
    case desktop = 4
}

public enum WinterGramIconPack: Int32 {
    case wintergram = 0
    case ayugram = 1
    case exteragram = 2
    case telegram = 3
}

// Style of the persistent top-center branding pill shown around the Dynamic Island / notch.
public enum WinterGramTopBannerStyle: Int32 {
    case off = 0
    case solid = 1
    case glass = 2
    case gradient = 3
    case outline = 4
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

public struct WinterGramSpoofPreset: Codable, Equatable {
    public var name: String
    public var deviceModel: String
    public var appVersion: String

    public init(name: String, deviceModel: String, appVersion: String) {
        self.name = name
        self.deviceModel = deviceModel
        self.appVersion = appVersion
    }
}

public struct WinterGramStashPrivacySettings: Codable, Equatable {
    public var profilePhoto: Bool
    public var phoneNumber: Bool
    public var presence: Bool
    public var forwards: Bool
    public var voiceCalls: Bool
    public var birthday: Bool
    public var giftsAutoSave: Bool
    public var bio: Bool
    public var savedMusic: Bool
    public var groupInvitations: Bool

    public static var defaultSettings: WinterGramStashPrivacySettings {
        return WinterGramStashPrivacySettings(
            profilePhoto: true,
            phoneNumber: false,
            presence: false,
            forwards: false,
            voiceCalls: false,
            birthday: false,
            giftsAutoSave: false,
            bio: false,
            savedMusic: false,
            groupInvitations: false
        )
    }

    public init(profilePhoto: Bool, phoneNumber: Bool, presence: Bool, forwards: Bool, voiceCalls: Bool, birthday: Bool, giftsAutoSave: Bool, bio: Bool, savedMusic: Bool, groupInvitations: Bool) {
        self.profilePhoto = profilePhoto
        self.phoneNumber = phoneNumber
        self.presence = presence
        self.forwards = forwards
        self.voiceCalls = voiceCalls
        self.birthday = birthday
        self.giftsAutoSave = giftsAutoSave
        self.bio = bio
        self.savedMusic = savedMusic
        self.groupInvitations = groupInvitations
    }

    public var hasAny: Bool {
        return self.profilePhoto || self.phoneNumber || self.presence || self.forwards || self.voiceCalls || self.birthday || self.giftsAutoSave || self.bio || self.savedMusic || self.groupInvitations
    }
}

public struct WinterGramVisualGift: Codable, Equatable {
    public var id: String
    public var gift: StarGift
    public var fromPeer: EnginePeer?

    public init(id: String, gift: StarGift, fromPeer: EnginePeer?) {
        self.id = id
        self.gift = gift
        self.fromPeer = fromPeer
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case gift
        case fromPeerId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.gift = try container.decode(StarGift.self, forKey: .gift)
        // `EnginePeer` isn't `Codable` and can't be rebuilt without a postbox, so — like
        // TelegramCore's own `StarGift` — only the peer id is persisted and `fromPeer` is left
        // nil on decode, to be resolved lazily by the consumer when a peer is actually needed.
        self.fromPeer = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.gift, forKey: .gift)
        try container.encodeIfPresent(self.fromPeer?.id, forKey: .fromPeerId)
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
    public var saveSelfDestructMessages: Bool
    public var hideFromBlocked: Bool
    public var semiTransparentDeletedMessages: Bool
    // Show the deletion time next to the deleted-message marker emoji.
    public var showDeletedTime: Bool

    // Hidden archive ("ААрхив")
    public var stashedPeerIds: [Int64]
    public var stashMuteNotifications: Bool
    public var stashAutoMarkRead: Bool
    public var stashPrivacy: WinterGramStashPrivacySettings
    // Optional passcode (digits) required to open the hidden stash; empty = no passcode.
    public var stashPasscode: String

    // Anti-features
    public var disableAds: Bool
    public var localPremium: Bool
    public var shadowBanIds: [Int64]
    public var disableStories: Bool
    public var hidePremiumStatuses: Bool
    public var disableOpenLinkWarning: Bool
    public var disableCopyProtection: Bool
    public var forwardWithoutAuthor: Bool
    public var allowScreenshots: Bool

    // Confirmations
    public var stickerConfirmation: Bool
    public var gifConfirmation: Bool
    public var voiceConfirmation: Bool
    public var confirmStoryView: Bool

    // Message decorations
    public var showMessageSeconds: Bool
    public var showPeerId: WinterGramPeerIdDisplay
    public var showRegistrationDate: Bool
    public var hideEditedMark: Bool
    public var deletedMark: String
    public var editedMark: String
    public var recentStickersCount: Int32

    // Translation
    public var translateMessages: Bool
    public var translationProvider: WinterGramTranslationProvider

    // Webview / platform spoofing
    public var webviewSpoofPlatform: WinterGramWebviewPlatform
    public var increaseWebviewHeight: Bool

    // Session device / app-version spoofing (applied at next launch). nil means real value.
    public var spoofDeviceModel: String?
    public var spoofAppVersion: String?
    public var spoofPresets: [WinterGramSpoofPreset]
    public var visualGifts: [WinterGramVisualGift]

    // Custom Telegram API credentials (applied at next launch). nil means the built-in values.
    public var customApiId: Int32?
    public var customApiHash: String?

    // Emoji used for the double-tap quick reaction; empty means Telegram's configured one.
    public var customDefaultReaction: String

    // Log online/offline transitions of peers whose chats you open.
    public var trackOnlineStatus: Bool

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
    public var useDefaultBranding: Bool
    public var topBannerStyle: WinterGramTopBannerStyle
    public var topBannerName: String

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
            saveSelfDestructMessages: false,
            hideFromBlocked: false,
            semiTransparentDeletedMessages: true,
            showDeletedTime: true,
            stashedPeerIds: [],
            stashMuteNotifications: true,
            stashAutoMarkRead: false,
            stashPrivacy: .defaultSettings,
            stashPasscode: "",
            disableAds: true,
            localPremium: false,
            shadowBanIds: [],
            disableStories: false,
            hidePremiumStatuses: false,
            disableOpenLinkWarning: false,
            disableCopyProtection: false,
            forwardWithoutAuthor: false,
            allowScreenshots: false,
            stickerConfirmation: false,
            gifConfirmation: false,
            voiceConfirmation: false,
            confirmStoryView: false,
            showMessageSeconds: false,
            showPeerId: .botApi,
            showRegistrationDate: false,
            hideEditedMark: false,
            deletedMark: "🧹",
            editedMark: "",
            recentStickersCount: 100,
            translateMessages: false,
            translationProvider: .telegram,
            webviewSpoofPlatform: .auto,
            increaseWebviewHeight: false,
            spoofDeviceModel: nil,
            spoofAppVersion: nil,
            spoofPresets: [],
            visualGifts: [],
            customApiId: nil,
            customApiHash: nil,
            customDefaultReaction: "",
            trackOnlineStatus: false,
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
            showOnlyAddedEmojisAndStickers: false,
            useDefaultBranding: false,
            topBannerStyle: .solid,
            topBannerName: "WntGramBanner"
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
        saveSelfDestructMessages: Bool,
        hideFromBlocked: Bool,
        semiTransparentDeletedMessages: Bool,
        showDeletedTime: Bool,
        stashedPeerIds: [Int64],
        stashMuteNotifications: Bool,
        stashAutoMarkRead: Bool,
        stashPrivacy: WinterGramStashPrivacySettings,
        stashPasscode: String,
        disableAds: Bool,
        localPremium: Bool,
        shadowBanIds: [Int64],
        disableStories: Bool,
        hidePremiumStatuses: Bool,
        disableOpenLinkWarning: Bool,
        disableCopyProtection: Bool,
        forwardWithoutAuthor: Bool,
        allowScreenshots: Bool,
        stickerConfirmation: Bool,
        gifConfirmation: Bool,
        voiceConfirmation: Bool,
        confirmStoryView: Bool,
        showMessageSeconds: Bool,
        showPeerId: WinterGramPeerIdDisplay,
        showRegistrationDate: Bool,
        hideEditedMark: Bool,
        deletedMark: String,
        editedMark: String,
        recentStickersCount: Int32,
        translateMessages: Bool,
        translationProvider: WinterGramTranslationProvider,
        webviewSpoofPlatform: WinterGramWebviewPlatform,
        increaseWebviewHeight: Bool,
        spoofDeviceModel: String?,
        spoofAppVersion: String?,
        spoofPresets: [WinterGramSpoofPreset],
        visualGifts: [WinterGramVisualGift],
        customApiId: Int32?,
        customApiHash: String?,
        customDefaultReaction: String,
        trackOnlineStatus: Bool,
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
        showOnlyAddedEmojisAndStickers: Bool,
        useDefaultBranding: Bool,
        topBannerStyle: WinterGramTopBannerStyle,
        topBannerName: String
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
        self.saveSelfDestructMessages = saveSelfDestructMessages
        self.hideFromBlocked = hideFromBlocked
        self.semiTransparentDeletedMessages = semiTransparentDeletedMessages
        self.showDeletedTime = showDeletedTime
        self.stashedPeerIds = stashedPeerIds
        self.stashMuteNotifications = stashMuteNotifications
        self.stashAutoMarkRead = stashAutoMarkRead
        self.stashPrivacy = stashPrivacy
        self.stashPasscode = stashPasscode
        self.disableAds = disableAds
        self.localPremium = localPremium
        self.shadowBanIds = shadowBanIds
        self.disableStories = disableStories
        self.hidePremiumStatuses = hidePremiumStatuses
        self.disableOpenLinkWarning = disableOpenLinkWarning
        self.disableCopyProtection = disableCopyProtection
        self.forwardWithoutAuthor = forwardWithoutAuthor
        self.allowScreenshots = allowScreenshots
        self.stickerConfirmation = stickerConfirmation
        self.gifConfirmation = gifConfirmation
        self.voiceConfirmation = voiceConfirmation
        self.confirmStoryView = confirmStoryView
        self.showMessageSeconds = showMessageSeconds
        self.showPeerId = showPeerId
        self.showRegistrationDate = showRegistrationDate
        self.hideEditedMark = hideEditedMark
        self.deletedMark = deletedMark
        self.editedMark = editedMark
        self.recentStickersCount = recentStickersCount
        self.translateMessages = translateMessages
        self.translationProvider = translationProvider
        self.webviewSpoofPlatform = webviewSpoofPlatform
        self.increaseWebviewHeight = increaseWebviewHeight
        self.spoofDeviceModel = spoofDeviceModel
        self.spoofAppVersion = spoofAppVersion
        self.spoofPresets = spoofPresets
        self.visualGifts = visualGifts
        self.customApiId = customApiId
        self.customApiHash = customApiHash
        self.customDefaultReaction = customDefaultReaction
        self.trackOnlineStatus = trackOnlineStatus
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
        self.useDefaultBranding = useDefaultBranding
        self.topBannerStyle = topBannerStyle
        self.topBannerName = topBannerName
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
        self.sendWithoutSound = WinterGramSendWithoutSound(rawValue: try container.decodeIfPresent(Int32.self, forKey: "sendWithoutSound") ?? defaults.sendWithoutSound.rawValue) ?? defaults.sendWithoutSound
        self.suggestGhostBeforeStory = try container.decodeIfPresent(Bool.self, forKey: "suggestGhostBeforeStory") ?? defaults.suggestGhostBeforeStory
        self.saveDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "saveDeletedMessages") ?? defaults.saveDeletedMessages
        self.saveMessagesHistory = try container.decodeIfPresent(Bool.self, forKey: "saveMessagesHistory") ?? defaults.saveMessagesHistory
        self.saveForBots = try container.decodeIfPresent(Bool.self, forKey: "saveForBots") ?? defaults.saveForBots
        self.saveSelfDestructMessages = try container.decodeIfPresent(Bool.self, forKey: "saveSelfDestructMessages") ?? defaults.saveSelfDestructMessages
        self.hideFromBlocked = try container.decodeIfPresent(Bool.self, forKey: "hideFromBlocked") ?? defaults.hideFromBlocked
        self.semiTransparentDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "semiTransparentDeletedMessages") ?? defaults.semiTransparentDeletedMessages
        self.showDeletedTime = try container.decodeIfPresent(Bool.self, forKey: "showDeletedTime") ?? defaults.showDeletedTime
        self.stashedPeerIds = try container.decodeIfPresent([Int64].self, forKey: "stashedPeerIds") ?? defaults.stashedPeerIds
        self.stashMuteNotifications = try container.decodeIfPresent(Bool.self, forKey: "stashMuteNotifications") ?? defaults.stashMuteNotifications
        self.stashAutoMarkRead = try container.decodeIfPresent(Bool.self, forKey: "stashAutoMarkRead") ?? defaults.stashAutoMarkRead
        if let legacyProfilePhoto = try container.decodeIfPresent(Bool.self, forKey: "stashHideProfilePhotoFromPeer") {
            var migrated = defaults.stashPrivacy
            migrated.profilePhoto = legacyProfilePhoto
            self.stashPrivacy = try container.decodeIfPresent(WinterGramStashPrivacySettings.self, forKey: "stashPrivacy") ?? migrated
        } else {
            self.stashPrivacy = try container.decodeIfPresent(WinterGramStashPrivacySettings.self, forKey: "stashPrivacy") ?? defaults.stashPrivacy
        }
        self.stashPasscode = try container.decodeIfPresent(String.self, forKey: "stashPasscode") ?? defaults.stashPasscode
        self.disableAds = try container.decodeIfPresent(Bool.self, forKey: "disableAds") ?? defaults.disableAds
        self.localPremium = try container.decodeIfPresent(Bool.self, forKey: "localPremium") ?? defaults.localPremium
        self.shadowBanIds = try container.decodeIfPresent([Int64].self, forKey: "shadowBanIds") ?? defaults.shadowBanIds
        self.disableStories = try container.decodeIfPresent(Bool.self, forKey: "disableStories") ?? defaults.disableStories
        self.hidePremiumStatuses = try container.decodeIfPresent(Bool.self, forKey: "hidePremiumStatuses") ?? defaults.hidePremiumStatuses
        self.disableOpenLinkWarning = try container.decodeIfPresent(Bool.self, forKey: "disableOpenLinkWarning") ?? defaults.disableOpenLinkWarning
        self.disableCopyProtection = try container.decodeIfPresent(Bool.self, forKey: "disableCopyProtection") ?? defaults.disableCopyProtection
        self.forwardWithoutAuthor = try container.decodeIfPresent(Bool.self, forKey: "forwardWithoutAuthor") ?? defaults.forwardWithoutAuthor
        self.allowScreenshots = try container.decodeIfPresent(Bool.self, forKey: "allowScreenshots") ?? defaults.allowScreenshots
        self.stickerConfirmation = try container.decodeIfPresent(Bool.self, forKey: "stickerConfirmation") ?? defaults.stickerConfirmation
        self.gifConfirmation = try container.decodeIfPresent(Bool.self, forKey: "gifConfirmation") ?? defaults.gifConfirmation
        self.voiceConfirmation = try container.decodeIfPresent(Bool.self, forKey: "voiceConfirmation") ?? defaults.voiceConfirmation
        self.confirmStoryView = try container.decodeIfPresent(Bool.self, forKey: "confirmStoryView") ?? defaults.confirmStoryView
        self.showMessageSeconds = try container.decodeIfPresent(Bool.self, forKey: "showMessageSeconds") ?? defaults.showMessageSeconds
        self.showPeerId = WinterGramPeerIdDisplay(rawValue: try container.decodeIfPresent(Int32.self, forKey: "showPeerId") ?? defaults.showPeerId.rawValue) ?? defaults.showPeerId
        self.showRegistrationDate = try container.decodeIfPresent(Bool.self, forKey: "showRegistrationDate") ?? defaults.showRegistrationDate
        self.hideEditedMark = try container.decodeIfPresent(Bool.self, forKey: "hideEditedMark") ?? defaults.hideEditedMark
        self.deletedMark = try container.decodeIfPresent(String.self, forKey: "deletedMark") ?? defaults.deletedMark
        self.editedMark = try container.decodeIfPresent(String.self, forKey: "editedMark") ?? defaults.editedMark
        self.recentStickersCount = try container.decodeIfPresent(Int32.self, forKey: "recentStickersCount") ?? defaults.recentStickersCount
        self.translateMessages = try container.decodeIfPresent(Bool.self, forKey: "translateMessages") ?? defaults.translateMessages
        self.translationProvider = WinterGramTranslationProvider(rawValue: try container.decodeIfPresent(Int32.self, forKey: "translationProvider") ?? defaults.translationProvider.rawValue) ?? defaults.translationProvider
        self.webviewSpoofPlatform = WinterGramWebviewPlatform(rawValue: try container.decodeIfPresent(Int32.self, forKey: "webviewSpoofPlatform") ?? defaults.webviewSpoofPlatform.rawValue) ?? defaults.webviewSpoofPlatform
        self.increaseWebviewHeight = try container.decodeIfPresent(Bool.self, forKey: "increaseWebviewHeight") ?? defaults.increaseWebviewHeight
        self.spoofDeviceModel = try container.decodeIfPresent(String.self, forKey: "spoofDeviceModel")
        self.spoofAppVersion = try container.decodeIfPresent(String.self, forKey: "spoofAppVersion")
        self.spoofPresets = try container.decodeIfPresent([WinterGramSpoofPreset].self, forKey: "spoofPresets") ?? defaults.spoofPresets
        self.visualGifts = try container.decodeIfPresent([WinterGramVisualGift].self, forKey: "visualGifts") ?? defaults.visualGifts
        self.customApiId = try container.decodeIfPresent(Int32.self, forKey: "customApiId")
        self.customApiHash = try container.decodeIfPresent(String.self, forKey: "customApiHash")
        self.customDefaultReaction = try container.decodeIfPresent(String.self, forKey: "customDefaultReaction") ?? defaults.customDefaultReaction
        self.trackOnlineStatus = try container.decodeIfPresent(Bool.self, forKey: "trackOnlineStatus") ?? defaults.trackOnlineStatus
        self.liquidGlass = try container.decodeIfPresent(WinterGramLiquidGlass.self, forKey: "liquidGlass") ?? defaults.liquidGlass
        self.materialDesign = try container.decodeIfPresent(Bool.self, forKey: "materialDesign") ?? defaults.materialDesign
        self.avatarCornerRadius = try container.decodeIfPresent(Int32.self, forKey: "avatarCornerRadius") ?? defaults.avatarCornerRadius
        self.singleCornerRadius = try container.decodeIfPresent(Bool.self, forKey: "singleCornerRadius") ?? defaults.singleCornerRadius
        self.messageBubbleRadius = try container.decodeIfPresent(Int32.self, forKey: "messageBubbleRadius") ?? defaults.messageBubbleRadius
        self.removeMessageTail = try container.decodeIfPresent(Bool.self, forKey: "removeMessageTail") ?? defaults.removeMessageTail
        self.customFont = try container.decodeIfPresent(String.self, forKey: "customFont")
        self.monoFont = try container.decodeIfPresent(String.self, forKey: "monoFont")
        self.appIcon = try container.decodeIfPresent(String.self, forKey: "appIcon") ?? defaults.appIcon
        self.iconPack = WinterGramIconPack(rawValue: try container.decodeIfPresent(Int32.self, forKey: "iconPack") ?? defaults.iconPack.rawValue) ?? defaults.iconPack
        self.showOnlyAddedEmojisAndStickers = try container.decodeIfPresent(Bool.self, forKey: "showOnlyAddedEmojisAndStickers") ?? defaults.showOnlyAddedEmojisAndStickers
        self.useDefaultBranding = try container.decodeIfPresent(Bool.self, forKey: "useDefaultBranding") ?? defaults.useDefaultBranding
        self.topBannerStyle = WinterGramTopBannerStyle(rawValue: try container.decodeIfPresent(Int32.self, forKey: "topBannerStyle") ?? defaults.topBannerStyle.rawValue) ?? defaults.topBannerStyle
        self.topBannerName = try container.decodeIfPresent(String.self, forKey: "topBannerName") ?? defaults.topBannerName
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
        try container.encode(self.sendWithoutSound.rawValue, forKey: "sendWithoutSound")
        try container.encode(self.suggestGhostBeforeStory, forKey: "suggestGhostBeforeStory")
        try container.encode(self.saveDeletedMessages, forKey: "saveDeletedMessages")
        try container.encode(self.saveMessagesHistory, forKey: "saveMessagesHistory")
        try container.encode(self.saveForBots, forKey: "saveForBots")
        try container.encode(self.saveSelfDestructMessages, forKey: "saveSelfDestructMessages")
        try container.encode(self.hideFromBlocked, forKey: "hideFromBlocked")
        try container.encode(self.semiTransparentDeletedMessages, forKey: "semiTransparentDeletedMessages")
        try container.encode(self.showDeletedTime, forKey: "showDeletedTime")
        try container.encode(self.stashedPeerIds, forKey: "stashedPeerIds")
        try container.encode(self.stashMuteNotifications, forKey: "stashMuteNotifications")
        try container.encode(self.stashAutoMarkRead, forKey: "stashAutoMarkRead")
        try container.encode(self.stashPrivacy, forKey: "stashPrivacy")
        try container.encode(self.stashPasscode, forKey: "stashPasscode")
        try container.encode(self.disableAds, forKey: "disableAds")
        try container.encode(self.localPremium, forKey: "localPremium")
        try container.encode(self.shadowBanIds, forKey: "shadowBanIds")
        try container.encode(self.disableStories, forKey: "disableStories")
        try container.encode(self.hidePremiumStatuses, forKey: "hidePremiumStatuses")
        try container.encode(self.disableOpenLinkWarning, forKey: "disableOpenLinkWarning")
        try container.encode(self.disableCopyProtection, forKey: "disableCopyProtection")
        try container.encode(self.forwardWithoutAuthor, forKey: "forwardWithoutAuthor")
        try container.encode(self.allowScreenshots, forKey: "allowScreenshots")
        try container.encode(self.stickerConfirmation, forKey: "stickerConfirmation")
        try container.encode(self.gifConfirmation, forKey: "gifConfirmation")
        try container.encode(self.voiceConfirmation, forKey: "voiceConfirmation")
        try container.encode(self.confirmStoryView, forKey: "confirmStoryView")
        try container.encode(self.showMessageSeconds, forKey: "showMessageSeconds")
        try container.encode(self.showPeerId.rawValue, forKey: "showPeerId")
        try container.encode(self.showRegistrationDate, forKey: "showRegistrationDate")
        try container.encode(self.hideEditedMark, forKey: "hideEditedMark")
        try container.encode(self.deletedMark, forKey: "deletedMark")
        try container.encode(self.editedMark, forKey: "editedMark")
        try container.encode(self.recentStickersCount, forKey: "recentStickersCount")
        try container.encode(self.translateMessages, forKey: "translateMessages")
        try container.encode(self.translationProvider.rawValue, forKey: "translationProvider")
        try container.encode(self.webviewSpoofPlatform.rawValue, forKey: "webviewSpoofPlatform")
        try container.encode(self.increaseWebviewHeight, forKey: "increaseWebviewHeight")
        try container.encodeIfPresent(self.spoofDeviceModel, forKey: "spoofDeviceModel")
        try container.encodeIfPresent(self.spoofAppVersion, forKey: "spoofAppVersion")
        try container.encode(self.spoofPresets, forKey: "spoofPresets")
        try container.encode(self.visualGifts, forKey: "visualGifts")
        try container.encodeIfPresent(self.customApiId, forKey: "customApiId")
        try container.encodeIfPresent(self.customApiHash, forKey: "customApiHash")
        try container.encode(self.customDefaultReaction, forKey: "customDefaultReaction")
        try container.encode(self.trackOnlineStatus, forKey: "trackOnlineStatus")
        try container.encode(self.liquidGlass, forKey: "liquidGlass")
        try container.encode(self.materialDesign, forKey: "materialDesign")
        try container.encode(self.avatarCornerRadius, forKey: "avatarCornerRadius")
        try container.encode(self.singleCornerRadius, forKey: "singleCornerRadius")
        try container.encode(self.messageBubbleRadius, forKey: "messageBubbleRadius")
        try container.encode(self.removeMessageTail, forKey: "removeMessageTail")
        try container.encodeIfPresent(self.customFont, forKey: "customFont")
        try container.encodeIfPresent(self.monoFont, forKey: "monoFont")
        try container.encode(self.appIcon, forKey: "appIcon")
        try container.encode(self.iconPack.rawValue, forKey: "iconPack")
        try container.encode(self.showOnlyAddedEmojisAndStickers, forKey: "showOnlyAddedEmojisAndStickers")
        try container.encode(self.useDefaultBranding, forKey: "useDefaultBranding")
        try container.encode(self.topBannerStyle.rawValue, forKey: "topBannerStyle")
        try container.encode(self.topBannerName, forKey: "topBannerName")
    }



    public func isShadowBanned(_ peerId: Int64) -> Bool {
        return self.shadowBanIds.contains(peerId)
    }

    public func isStashed(_ peerId: Int64) -> Bool {
        return self.stashedPeerIds.contains(peerId)
    }

    // MARK: - Ghost-mode decision helpers (pure, unit-testable)

    // These forward to WinterGramGhostLogic (a pure, standalone-testable file).

    /// Read receipts must be withheld (the other side won't see "read").
    public var suppressesReadReceipts: Bool {
        return WinterGramGhostLogic.suppressesReadReceipts(ghostModeEnabled: self.ghostModeEnabled, sendReadReceipts: self.sendReadReceipts)
    }

    /// Online presence must be withheld (appear offline).
    public var suppressesOnlinePresence: Bool {
        return WinterGramGhostLogic.suppressesOnlinePresence(ghostModeEnabled: self.ghostModeEnabled, sendOnlineStatus: self.sendOnlineStatus)
    }

    /// Typing / upload activity must be withheld.
    public var suppressesTypingStatus: Bool {
        return WinterGramGhostLogic.suppressesTypingStatus(ghostModeEnabled: self.ghostModeEnabled, sendUploadProgress: self.sendUploadProgress)
    }

    /// Story views must be withheld (don't mark stories seen).
    public var suppressesStoryViews: Bool {
        return WinterGramGhostLogic.suppressesStoryViews(ghostModeEnabled: self.ghostModeEnabled, sendReadStories: self.sendReadStories)
    }

    /// When reads are suppressed but the user took an explicit action (sent a message),
    /// the active chat should still be marked read.
    public var shouldMarkReadAfterAction: Bool {
        return WinterGramGhostLogic.shouldMarkReadAfterAction(ghostModeEnabled: self.ghostModeEnabled, sendReadReceipts: self.sendReadReceipts, markReadAfterAction: self.markReadAfterAction)
    }

    /// After an action forces the client online, immediately drop back to offline.
    public var shouldGoOfflineAfterAction: Bool {
        return WinterGramGhostLogic.shouldGoOfflineAfterAction(ghostModeEnabled: self.ghostModeEnabled, sendOfflineAfterOnline: self.sendOfflineAfterOnline)
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
        // Bridge branding to standard UserDefaults so the early-launch intro (Obj-C,
        // runs before the settings store is up) can pick the title synchronously.
        UserDefaults.standard.set(settings.useDefaultBranding, forKey: "wnt_useDefaultBranding")
        // Bridge session spoof values to standard UserDefaults so the network stack, which is
        // initialized at launch before the settings store is up, can read them synchronously.
        // These take effect on the next launch.
        if let spoofDeviceModel = settings.spoofDeviceModel, !spoofDeviceModel.isEmpty {
            UserDefaults.standard.set(spoofDeviceModel, forKey: "wnt_spoofDeviceModel")
        } else {
            UserDefaults.standard.removeObject(forKey: "wnt_spoofDeviceModel")
        }
        if let spoofAppVersion = settings.spoofAppVersion, !spoofAppVersion.isEmpty {
            UserDefaults.standard.set(spoofAppVersion, forKey: "wnt_spoofAppVersion")
        } else {
            UserDefaults.standard.removeObject(forKey: "wnt_spoofAppVersion")
        }
        // Custom API credentials (applied at next launch). Both must be set to take effect.
        if let customApiId = settings.customApiId, customApiId != 0, let customApiHash = settings.customApiHash, !customApiHash.isEmpty {
            UserDefaults.standard.set(Int(customApiId), forKey: "wnt_customApiId")
            UserDefaults.standard.set(customApiHash, forKey: "wnt_customApiHash")
        } else {
            UserDefaults.standard.removeObject(forKey: "wnt_customApiId")
            UserDefaults.standard.removeObject(forKey: "wnt_customApiHash")
        }
        let webviewPlatform: String?
        switch settings.webviewSpoofPlatform {
        case .auto:
            webviewPlatform = nil
        case .ios:
            webviewPlatform = "ios"
        case .android:
            webviewPlatform = "android"
        case .macos:
            webviewPlatform = "macos"
        case .desktop:
            webviewPlatform = "tdesktop"
        }
        setCurrentWinterGramCoreSettings(WinterGramCoreSettings(
            saveDeletedMessages: settings.saveDeletedMessages,
            saveMessageEditHistory: settings.saveMessagesHistory,
            saveForBots: settings.saveForBots,
            saveSelfDestructMessages: settings.saveSelfDestructMessages,
            allowScreenshots: settings.allowScreenshots,
            webviewPlatform: webviewPlatform
        ))
    })
}

public func isWinterGramOfficialPeer(_ peer: EnginePeer) -> Bool {
    let peerIdValue = peer.id.id._internalGetInt64Value()
    switch peer {
    case .user:
        return peerIdValue == 885166226 || peerIdValue == 5665997196
    case .channel:
        // Raw channel ids (the part after the -100 marker): @wntgram/@wntbeta plus -1003999337820 / -1004348385636.
        return peerIdValue == 3943351959 || peerIdValue == 4316373875 || peerIdValue == 3999337820 || peerIdValue == 4348385636
    default:
        return false
    }
}

// Developer accounts get a distinct backplated badge; other official peers keep the plain snowflake.
public func isWinterGramDeveloperPeer(_ peer: EnginePeer) -> Bool {
    let peerIdValue = peer.id.id._internalGetInt64Value()
    switch peer {
    case .user:
        return peerIdValue == 885166226 || peerIdValue == 5665997196
    default:
        return false
    }
}

// Name of the bundled badge image for a peer, or nil if the peer carries no WinterGram badge.
// Developers and official channels get the backplated badge; other official peers get the plain snowflake.
public func winterGramBadgeImageName(for peer: EnginePeer) -> String? {
    if isWinterGramDeveloperPeer(peer) {
        return "WntGramDeveloperBadge"
    }
    if isWinterGramOfficialPeer(peer) {
        if case .channel = peer {
            return "WntGramDeveloperBadge"
        }
        return "WinterGramSnowflake"
    }
    return nil
}
