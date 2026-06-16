# WinterGram Features

This document describes every user-facing WinterGram capability. Settings are grouped under the **WinterGram** tab in the app (Settings → WinterGram).

---

## Ghost Mode

Control what activity signals you send to Telegram servers.

| Feature | Description |
| :-- | :-- |
| Ghost Mode presets | Off, Messages only, Stories only, or Everything |
| Send without sound | Never, only in Ghost Mode, or always |
| Scheduled send trick | Route ghost-mode sends through the scheduled path so the chat stays unread |
| Track online status | Local log of when contacts go online (Online Tracker screen) |
| Story ghost | View stories without marking them seen |
| Mark read after action | Mark chats read locally after you reply or react, without sending receipts |
| Go offline after online | Send a one-shot offline presence after appearing online |

---

## History and Recovery

Keep message content on this device even when it is removed or changed on the server.

| Feature | Description |
| :-- | :-- |
| Save deleted messages | Retain messages after the other side deletes them |
| Save edit history | Store every revision of edited messages |
| Save from bots | Include bot messages in the deleted-message cache |
| Save self-destruct | Keep disappearing messages before they vanish |
| Dim deleted messages | Render saved deletions at reduced opacity |
| Clear saved deletions | Remove all locally cached deleted messages |
| Deleted messages browser | Data & Storage → Deleted Messages: pie chart by type, per-category cleanup, **top chats** by deletion count |

---

## Hidden Archive

A separate stash for chats that should not appear in the main list.

| Feature | Description |
| :-- | :-- |
| Stash chats | Move chats to a settings-only archive via context menu |
| Stashed chats list | Browse and unstash from WinterGram → Core → Hidden Archive |
| Mute notifications | Drop in-app banners for stashed peers |
| Auto mark as read | Mark incoming stashed messages read locally |
| Passcode | Optional passcode gate before opening the stash |

---

## Features (anti-features and conveniences)

| Feature | Description |
| :-- | :-- |
| Disable ads | Hide sponsored messages in channels |
| Local Premium | Unlock Premium-gated UI locally (no server-side subscription) |
| Hide stories | Remove stories from the chat list header |
| Hide Premium statuses | Conceal Premium badges and statuses |
| Disable open-link warning | Skip the concealed-URL confirmation dialog |
| Allow saving restricted content | Bypass copy-protection on protected media |
| Allow screenshots everywhere | Disable screenshot blocking in supported views |
| Confirm stickers / GIFs / voice | Ask before sending each media type |

---

## Chat

| Feature | Description |
| :-- | :-- |
| Show message seconds | Display seconds in message timestamps |
| Show peer ID | Hidden, Telegram API form, or Bot API form in profiles |
| Show registration date | Display account creation date where available |
| Hide edited mark | Suppress the "edited" label on messages |
| Message translation | Context-menu translation with selectable provider |
| Translation provider | Telegram, Google, Yandex, or system |
| Increase WebView height | Taller viewport for mini-apps |
| Only added emoji and stickers | Limit picker to your custom sets |
| Forward without author | Omit original author on forwards |
| Default reaction | Custom emoji reaction used by default |

---

## Appearance

| Feature | Description |
| :-- | :-- |
| Material Design | Material-styled switches and controls |
| Single corner radius | Apply bubble radius to one corner only |
| Avatar shape | Slider from square through squircle to round |
| Bubble radius | Adjustable message bubble corner radius |
| Custom font | Override the UI typeface |
| Monospace font | Override the code/monospace typeface |
| Icon pack | WinterGram, Ayu, exteraGram, or Telegram alternate icons |
| Liquid Glass | Frosted translucent surfaces with per-area toggles |
| Liquid Glass vibrancy | Extra vibrancy on glass layers |
| Apply to chat list / nav bars / tab bar / bubbles | Per-surface glass control |

---

## Spoofing

Report different device metadata to Telegram and mini-apps. Changing API credentials requires re-login.

| Feature | Description |
| :-- | :-- |
| Spoof device model | Override the hardware identifier |
| Spoof app version | Override the client version string |
| WebView platform | Automatic, iOS, Android, macOS, or desktop |
| Custom API ID / Hash | Use your own credentials from my.telegram.org |
| Spoof presets | Save and recall device/version profiles |

---

## Badges and Branding

| Feature | Description |
| :-- | :-- |
| WinterGram badge | Composed at runtime from white backplate + snowflake shapes, tinted to the theme |
| Developer badge | Backplated snowflake for contributors |
| Official channel badge | Snowflake for official WinterGram resources |
| Use default branding | Restore standard Telegram naming in the UI |

---

## Accounts and Data

| Feature | Description |
| :-- | :-- |
| Multiple accounts | Up to 100 accounts on one device |
| Deep links | `wnt://` scheme mirrors `tg://`; `wnt://wintergram/<section>` opens a settings category |
| Local-only storage | Deleted and edited history never leaves the device |
| iCloud backup | Account data is included in device backups |

---

## Localization

| Language | Coverage |
| :-- | :-- |
| English | All WinterGram settings strings |
| Russian | Full WinterGram UI via bundled seed translations |

---

## Channels and Links

| Resource | URL |
| :-- | :-- |
| Channel | https://t.me/wntgram |
| Beta | https://t.me/wntbeta |
| GitHub | https://github.com/reekeer/WinterGram |
