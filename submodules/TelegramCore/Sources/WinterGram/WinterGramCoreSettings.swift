import Foundation
import SwiftSignalKit

public struct WinterGramCoreSettings: Equatable {
    public var saveDeletedMessages: Bool
    public var saveMessageEditHistory: Bool
    // When false, deletions in bot chats are not preserved even if saveDeletedMessages is on.
    public var saveForBots: Bool
    // Preserve self-destructing / view-once secret-chat messages instead of letting them expire.
    public var saveSelfDestructMessages: Bool
    // Disable screenshot reporting in secret chats and capture-protection in galleries.
    public var allowScreenshots: Bool
    // Platform string sent to bots when opening a web view ("ios", "android",
    // "macos", "tdesktop"); nil means the real platform.
    public var webviewPlatform: String?

    public init(saveDeletedMessages: Bool, saveMessageEditHistory: Bool, saveForBots: Bool = false, saveSelfDestructMessages: Bool = false, allowScreenshots: Bool = false, webviewPlatform: String? = nil) {
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessageEditHistory = saveMessageEditHistory
        self.saveForBots = saveForBots
        self.saveSelfDestructMessages = saveSelfDestructMessages
        self.allowScreenshots = allowScreenshots
        self.webviewPlatform = webviewPlatform
    }

    public static var defaultSettings: WinterGramCoreSettings {
        return WinterGramCoreSettings(saveDeletedMessages: false, saveMessageEditHistory: false, saveForBots: false, saveSelfDestructMessages: false, allowScreenshots: false, webviewPlatform: nil)
    }
}

private let currentValue = Atomic<WinterGramCoreSettings>(value: .defaultSettings)

// TelegramCore cannot depend on TelegramUIPreferences, so the UI layer pushes
// the relevant flags here at startup and on every settings change.
public var currentWinterGramCoreSettings: WinterGramCoreSettings {
    return currentValue.with { $0 }
}

public func setCurrentWinterGramCoreSettings(_ settings: WinterGramCoreSettings) {
    let _ = currentValue.swap(settings)
}
