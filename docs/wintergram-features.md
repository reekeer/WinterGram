# WinterGram — feature → implementation map

This document maps every WinterGram option to where it is (or needs to be) wired into the
Telegram-iOS codebase. The settings themselves live in a single store:

- `submodules/TelegramUIPreferences/Sources/WinterGramSettings.swift` — the `WinterGramSettings`
  `Codable` struct, its sub-structs (`WinterGramLiquidGlass`) and enums, plus
  `updateWinterGramSettingsInteractively(...)` and `winterGramSettings(accountManager:)`.
- `submodules/TelegramUIPreferences/Sources/PostboxKeys.swift` — the shared-data key
  `ApplicationSpecificSharedDataKeys.winterGramSettings` (value `23`).

Read the store anywhere that already has an `AccountContext` / `AccountManager` via
`winterGramSettings(accountManager:)`, and write it via `updateWinterGramSettingsInteractively`.

## Status legend

- **Store** — the setting exists and persists (done in this repo).
- **Hook** — the place in the app where behavior must read the setting.

## Privacy & Ghost Mode

| Setting | Hook |
| :-- | :-- |
| `ghostModeEnabled` | Master switch read by the read-receipt / online-status / typing senders below. |
| `sendReadReceipts` | `TelegramCore` history read — gate `_internal_applyMaxReadIndex` / outgoing `messages.readHistory` calls. |
| `sendReadStories` | Story view reporting — gate `markStoryAsSeen` network calls. |
| `sendOnlineStatus` | Online presence — gate `account.updatePresence` / `updateStatus`. |
| `sendUploadProgress` | Typing/upload activity — gate `ChatActivity` / `setTyping` reporting. |
| `sendOfflineAfterOnline` | Emit a one-shot offline presence packet after the app goes online. |
| `markReadAfterAction` | After replying/reacting, locally mark the chat read without sending receipts. |
| `useScheduledMessages` | "Отложка" — when ghosting, send via the scheduled-messages path. |
| `sendWithoutSound` | Outgoing message flags — set `silent` per `shouldSendWithoutSound`. |
| `suggestGhostBeforeStory` | Story viewer — present the ghost confirmation before opening. |

## History & Recovery

| Setting | Hook |
| :-- | :-- |
| `saveDeletedMessages` | Hook the deletion path in `Postbox` history removal; mirror messages into a local store before they are purged. |
| `saveMessagesHistory` | On `EditMessage` updates, append the previous version to a local edit-history store. |
| `semiTransparentDeletedMessages` | `ChatMessageItemView` — render saved-deleted bubbles at reduced alpha. |
| `deletedMark` / `editedMark` | Message footer rendering in the bubble content nodes. |

## Hidden Archive ("AАrchive")

| Setting | Hook |
| :-- | :-- |
| `stashedPeerIds` | Filter the chat list to hide these peers from the main list; show them only in the dedicated WinterGram archive screen. |
| `stashMuteNotifications` | Notification service extension — suppress notifications for stashed peers. |
| `stashAutoMarkRead` | On receiving from a stashed peer, locally mark read (respecting Ghost Mode). |

## Anti-Features

| Setting | Hook |
| :-- | :-- |
| `disableAds` | Sponsored-messages fetch in `TelegramCore` (`getAdMessages`) — return empty when disabled. |
| `localPremium` | `isPremium` resolution in the UI layer — treat as Premium locally for gated UI. |
| `shadowBanIds` | Chat history filtering — drop incoming messages from these peers from the rendered list. |
| `disableStories` | Story list assembly — hide the stories strip. |
| `hidePremiumStatuses` | Peer title rendering — drop Premium/emoji-status badges. |
| `disableOpenLinkWarning` | URL open path — skip the "open this link?" confirmation. |

## Chat Conveniences

| Setting | Hook |
| :-- | :-- |
| `stickerConfirmation` / `gifConfirmation` / `voiceConfirmation` | Send paths in the chat input panel — present a confirm alert before sending. |
| `showMessageSeconds` | Timestamp formatting in the bubble footer. |
| `showPeerId` | Peer info / chat title — append the ID in Telegram or Bot API form. |
| `translateMessages` / `translationProvider` | Message context menu translate action + provider selection. |
| `webviewSpoofPlatform` / `increaseWebviewHeight` | WebApp controller — set the spoofed `tg_platform` / viewport height. |

## Appearance & Customization

| Setting | Hook |
| :-- | :-- |
| `liquidGlass.*` | `Display` blur/material layers behind the chat list, nav bar, and tab bar; read `enabled`, `transparency`, `blurRadius`, `tintColor`, per-surface flags. |
| `materialDesign` | Switch/control styling in `ItemListUI` components. |
| `avatarCornerRadius` / `singleCornerRadius` | Avatar node corner rounding in `AvatarNode`. |
| `messageBubbleRadius` / `removeMessageTail` | Bubble background drawing in the chat message backgrounds. |
| `customFont` / `monoFont` | `PresentationData` font resolution. |
| `appIcon` / `iconPack` | Alternate-icon switching via `UIApplication.setAlternateIconName`; see `Telegram/Telegram-iOS/DefaultAppIcon.xcassets/WinterGramDarkIcon.appiconset`. |
| `showOnlyAddedEmojisAndStickers` | Emoji/sticker panel data sources — filter to installed packs. |

## Deep links — `wnt://`

Registered in `Telegram/Telegram-iOS/Info.plist` and `InfoBazel.plist` (alongside `tg`).
Normalized to `tg://` at the app entry by `normalizeWinterGramUrlScheme(_:)` in
`submodules/TelegramUI/Sources/AppDelegate.swift`, so every `tg://` route also accepts `wnt://`.

## Settings UI

A dedicated **WinterGram** entry should be added to the settings list
(`submodules/SettingsUI` / the PeerInfo settings screen) that opens an `ItemListController`
backed by `winterGramSettings(accountManager:)` and writing through
`updateWinterGramSettingsInteractively`. Group the rows by the sections above.
