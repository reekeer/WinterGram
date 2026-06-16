import Foundation

// Standalone unit tests for the ghost-mode decision logic.
//
// This project has no Bazel test harness, but WinterGramGhostLogic.swift is
// dependency-free, so it can be compiled and run directly:
//
//   swiftc \
//     submodules/TelegramUIPreferences/Sources/WinterGramGhostLogic.swift \
//     Tests/WinterGram/WinterGramGhostLogicTests.swift \
//     -o /tmp/wnt_tests && /tmp/wnt_tests
//
// The functions tested here are the exact ones WinterGramSettings forwards to,
// so a regression in the shipping rules fails these tests.

@main
struct WinterGramGhostLogicTests {
    static var failures = 0
    static var checks = 0

    static func expect(_ actual: Bool, _ expected: Bool, _ label: String) {
        checks += 1
        if actual != expected {
            failures += 1
            print("FAIL: \(label) — expected \(expected), got \(actual)")
        }
    }

    static func main() {
        let G = WinterGramGhostLogic.self

        // suppressesReadReceipts: only when ghost ON and receipts OFF.
        expect(G.suppressesReadReceipts(ghostModeEnabled: true, sendReadReceipts: false), true, "readReceipts ghost+off")
        expect(G.suppressesReadReceipts(ghostModeEnabled: true, sendReadReceipts: true), false, "readReceipts ghost+on")
        expect(G.suppressesReadReceipts(ghostModeEnabled: false, sendReadReceipts: false), false, "readReceipts noghost+off")
        expect(G.suppressesReadReceipts(ghostModeEnabled: false, sendReadReceipts: true), false, "readReceipts noghost+on")

        // suppressesOnlinePresence
        expect(G.suppressesOnlinePresence(ghostModeEnabled: true, sendOnlineStatus: false), true, "online ghost+off")
        expect(G.suppressesOnlinePresence(ghostModeEnabled: true, sendOnlineStatus: true), false, "online ghost+on")
        expect(G.suppressesOnlinePresence(ghostModeEnabled: false, sendOnlineStatus: false), false, "online noghost+off")

        // suppressesTypingStatus
        expect(G.suppressesTypingStatus(ghostModeEnabled: true, sendUploadProgress: false), true, "typing ghost+off")
        expect(G.suppressesTypingStatus(ghostModeEnabled: false, sendUploadProgress: false), false, "typing noghost+off")

        // suppressesStoryViews
        expect(G.suppressesStoryViews(ghostModeEnabled: true, sendReadStories: false), true, "story ghost+off")
        expect(G.suppressesStoryViews(ghostModeEnabled: true, sendReadStories: true), false, "story ghost+on")

        // shouldMarkReadAfterAction: requires reads suppressed AND the toggle on.
        expect(G.shouldMarkReadAfterAction(ghostModeEnabled: true, sendReadReceipts: false, markReadAfterAction: true), true, "markRead suppressed+toggle")
        expect(G.shouldMarkReadAfterAction(ghostModeEnabled: true, sendReadReceipts: false, markReadAfterAction: false), false, "markRead suppressed+notoggle")
        expect(G.shouldMarkReadAfterAction(ghostModeEnabled: true, sendReadReceipts: true, markReadAfterAction: true), false, "markRead notsuppressed+toggle")
        expect(G.shouldMarkReadAfterAction(ghostModeEnabled: false, sendReadReceipts: false, markReadAfterAction: true), false, "markRead noghost+toggle")

        // shouldGoOfflineAfterAction: requires ghost ON and the toggle on.
        expect(G.shouldGoOfflineAfterAction(ghostModeEnabled: true, sendOfflineAfterOnline: true), true, "offline ghost+toggle")
        expect(G.shouldGoOfflineAfterAction(ghostModeEnabled: true, sendOfflineAfterOnline: false), false, "offline ghost+notoggle")
        expect(G.shouldGoOfflineAfterAction(ghostModeEnabled: false, sendOfflineAfterOnline: true), false, "offline noghost+toggle")

        if failures == 0 {
            print("OK: all \(checks) ghost-logic checks passed")
            exit(0)
        } else {
            print("\(failures)/\(checks) checks FAILED")
            exit(1)
        }
    }
}
