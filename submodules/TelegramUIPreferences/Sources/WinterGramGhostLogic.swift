import Foundation

// Pure, dependency-free ghost-mode decision logic.
//
// This file deliberately imports nothing beyond Foundation so it can be compiled
// and unit-tested standalone (see Tests/WinterGram/WinterGramGhostLogicTests.swift),
// without pulling in TelegramCore / the Bazel module graph. WinterGramSettings'
// computed gate properties forward to these functions, so the tests exercise the
// exact rules the app ships.

public enum WinterGramGhostLogic {
    /// Read receipts must be withheld (the other side won't see "read").
    public static func suppressesReadReceipts(ghostModeEnabled: Bool, sendReadReceipts: Bool) -> Bool {
        return ghostModeEnabled && !sendReadReceipts
    }

    /// Online presence must be withheld (appear offline).
    public static func suppressesOnlinePresence(ghostModeEnabled: Bool, sendOnlineStatus: Bool) -> Bool {
        return ghostModeEnabled && !sendOnlineStatus
    }

    /// Typing / upload activity must be withheld.
    public static func suppressesTypingStatus(ghostModeEnabled: Bool, sendUploadProgress: Bool) -> Bool {
        return ghostModeEnabled && !sendUploadProgress
    }

    /// Story views must be withheld (don't mark stories seen).
    public static func suppressesStoryViews(ghostModeEnabled: Bool, sendReadStories: Bool) -> Bool {
        return ghostModeEnabled && !sendReadStories
    }

    /// When reads are suppressed but the user took an explicit action (sent a message),
    /// the active chat should still be marked read.
    public static func shouldMarkReadAfterAction(ghostModeEnabled: Bool, sendReadReceipts: Bool, markReadAfterAction: Bool) -> Bool {
        return suppressesReadReceipts(ghostModeEnabled: ghostModeEnabled, sendReadReceipts: sendReadReceipts) && markReadAfterAction
    }

    /// After an action forces the client online, immediately drop back to offline.
    public static func shouldGoOfflineAfterAction(ghostModeEnabled: Bool, sendOfflineAfterOnline: Bool) -> Bool {
        return ghostModeEnabled && sendOfflineAfterOnline
    }
}
