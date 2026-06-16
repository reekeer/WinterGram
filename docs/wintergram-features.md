# WinterGram — feature → implementation map

> Developer reference. User-facing overview: [`docs/FEATURES.md`](FEATURES.md).

This document maps every WinterGram option to where it is wired into the
codebase. The settings themselves live in a single store:

- `submodules/TelegramUIPreferences/Sources/WinterGramSettings.swift` — the `WinterGramSettings`
  `Codable` struct, its sub-structs (`WinterGramLiquidGlass`) and enums, plus
  `updateWinterGramSettingsInteractively(...)`, `winterGramSettings(accountManager:)`, and the
  synchronous snapshot `currentWinterGramSettings` (kept fresh by
  `observeWinterGramSettings(accountManager:)`, started from `AppDelegate`).
- `submodules/TelegramUIPreferences/Sources/PostboxKeys.swift` — the shared-data key
  `ApplicationSpecificSharedDataKeys.winterGramSettings` (value `23`).
- `submodules/TelegramCore/Sources/WinterGram/WinterGramCoreSettings.swift` — a minimal
  mirror for hooks inside `TelegramCore` (which cannot import `TelegramUIPreferences`);
  fed by the same observer.

Read the store anywhere that already has an `AccountContext` / `AccountManager` via
`winterGramSettings(accountManager:)` (reactive) or `currentWinterGramSettings` (sync),
and write it via `updateWinterGramSettingsInteractively`.

## Status legend

- ✅ — setting persists and the behavior hook is in place.
- ⏳ — setting persists, behavior not fully hooked yet.

## Privacy & Ghost Mode

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `ghostModeEnabled` | ✅ | Master switch read by the gates below. |
| `sendReadReceipts` | ✅ | `AccountContext.applyMaxReadIndex` (`submodules/TelegramUI/Sources/AccountContext.swift`) returns early in ghost mode. |
| `sendReadStories` | ✅ | All four `markAsSeen` implementations in `StoryChatContent.swift` return early in ghost mode. |
| `sendOnlineStatus` | ✅ | `SharedWakeupManager` forces `shouldKeepOnlinePresence` to false in ghost mode. |
| `sendUploadProgress` | ✅ | Typing-activity subscription in `ChatController.swift` skips `updateLocalInputActivity` in ghost mode. |
| `sendOfflineAfterOnline` | ⏳ | Emit a one-shot offline presence packet after going online. |
| `markReadAfterAction` | ⏳ | After replying/reacting, locally mark read without sending receipts. |
| `useScheduledMessages` | ✅ | "Отложка": `transformEnqueueMessages` in `ChatController.swift` routes ghost-mode sends through the scheduled path (now + 12 s) so sending doesn't mark the chat read. |
| `sendWithoutSound` | ✅ | `transformEnqueueMessages` computes `effectiveSilentPosting` from never / in-ghost / always. |
| `suggestGhostBeforeStory` | ⏳ | Story viewer — present the ghost confirmation before opening. |

## History & Recovery

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `saveDeletedMessages` | ✅ | Remote deletions (`.DeleteMessages` / `.DeleteMessagesWithGlobalIds`) skipped in `AccountStateManagementUtils.swift` via `currentWinterGramCoreSettings`. |
| `saveMessagesHistory` | ✅ | On remote `.EditMessage`, the previous text/entities/timestamp are appended to `WinterGramEditHistoryAttribute` (`submodules/TelegramCore/Sources/WinterGram/`); registered in `AccountManager.swift`. Viewing UI: ⏳. |
| `semiTransparentDeletedMessages` | ⏳ | Render kept-deleted bubbles at reduced alpha. |

## Hidden Archive ("ААрхив")

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `stashedPeerIds` | ✅ | Hidden from the main tab in `ChatListNodeEntries.swift`; stash/unstash via chat-list context menu (`ChatContextMenus.swift`); browse via Settings → WinterGram → Stashed Chats (`WinterGramStashController.swift`). |
| `stashMuteNotifications` | ✅ | In-app notification pipeline in `ApplicationContext.swift` drops banners for stashed peers. (APNs pushes need the NotificationService extension: ⏳.) |
| `stashAutoMarkRead` | ✅ | Same pipeline calls `applyMaxReadIndexInteractively` for stashed peers. |

## Anti-Features

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `disableAds` | ✅ | Ad insertion gate in `ChatHistoryEntriesForView.swift`. |
| `localPremium` | ✅ | `isPremium` resolution in `submodules/TelegramUI/Sources/AccountContext.swift`. |
| `shadowBanIds` | ✅ | Entry filter by author in `ChatHistoryEntriesForView.swift`. |
| `disableStories` | ✅ | `shouldDisplayStoriesInChatListHeader` in `ChatListControllerNode.swift` returns false. |
| `hidePremiumStatuses` | ✅ | `ChatTitleView` / `ChatTitleComponent` / `ChatListItem` / `ItemListPeerItem`. |
| `disableOpenLinkWarning` | ✅ | Concealed-link alert gate in `OpenUserGeneratedUrl.swift`. |

## In-app purchases

Fully disabled: `InAppPurchaseManager.buyProduct` fails immediately with `.cantMakePayments`
(every purchase screen maps that to a localized error), and `PremiumIntroScreen.buy()` shows a
"subscribe via the official Telegram app" alert before reaching the manager. Redeeming gift
codes still works (not an IAP).

## Chat Conveniences

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `stickerConfirmation` / `gifConfirmation` | ✅ | `ChatController.swift` send paths. |
| `voiceConfirmation` | ✅ | `ChatControllerMediaRecording.swift`. |
| `showMessageSeconds` | ✅ | `StringForMessageTimestampStatus.swift`. |
| `showPeerId` | ✅ | ID row (long-press copies) in `PeerInfoProfileItems.swift` for users and channels/groups, honoring Telegram/Bot-API format. |
| `translateMessages` / `translationProvider` | ⏳ | Message context-menu translate + provider. |
| `webviewSpoofPlatform` | ✅ | `BotWebView.swift` in TelegramCore reads `currentWinterGramCoreSettings.webviewPlatform` (ios / android / macos / tdesktop), fed by the settings observer. |
| `increaseWebviewHeight` | ⏳ | WebApp controller viewport. |

## Appearance & Customization

| Setting | Status | Hook |
| :-- | :-- | :-- |
| `liquidGlass.*` | ⏳ | Blur/material layers behind chat list, nav bar, tab bar. |
| `materialDesign` | ⏳ | Switch/control styling. |
| `avatarCornerRadius` / `singleCornerRadius` | ⏳ | `AvatarNode` corner rounding. Note: photos are circle-clipped inside the bitmap (`PeerAvatar.swift` `roundCorners` mask), so a real implementation must touch every render path, not just `imageNode.cornerRadius`. |
| `messageBubbleRadius` / `removeMessageTail` | ⏳ | Bubble background drawing. |
| `customFont` / `monoFont` | ⏳ | `PresentationData` font resolution. |
| `appIcon` / `iconPack` | ⏳ | Alternate-icon switching; assets in `DefaultAppIcon.xcassets/WinterGramDarkIcon.appiconset`. |
| `showOnlyAddedEmojisAndStickers` | ⏳ | Emoji/sticker panel data sources. |

## Accounts

- Unlimited accounts: `maximumNumberOfAccounts` / `maximumPremiumNumberOfAccounts` = 100 in
  `submodules/AccountUtils/Sources/AccountUtils.swift`; the add-account flow in
  `PeerInfoScreenSettingsActions.swift` uses the same constants.
- Account data is included in iCloud/iTunes device backups (`isExcludedFromBackup = false` in
  `TelegramCore/Sources/Account/AccountManager.swift`). Tradeoff: session auth keys become part
  of the backup.

## Deep links — `wnt://`

Registered in `Telegram/Telegram-iOS/Info.plist` and `InfoBazel.plist` (alongside `tg`).
Normalized to `tg://` at the app entry by `normalizeWinterGramUrlScheme(_:)` in
`submodules/TelegramUI/Sources/AppDelegate.swift`, so every `tg://` route also accepts `wnt://`.

## Settings UI

The **WinterGram** entry is the first row of Settings (snowball icon,
`PresentationResourcesSettings.winterGram`), opening
`submodules/SettingsUI/Sources/WinterGramSettingsController.swift`. The Hidden Archive browser
lives in `WinterGramStashController.swift` next to it.
