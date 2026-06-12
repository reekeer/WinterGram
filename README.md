<h1 align="center">WinterGram</h1>

<h4 align="center">WinterGram (Wnt) is a feature-rich, privacy-focused Telegram client for iPhone — a native iOS port of the AyuGram experience, built on top of Telegram-iOS.</h4>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv2-green?style=for-the-badge&logo=gnu&logoColor=FFFFFF" alt="License"></a>
  <img src="https://img.shields.io/badge/Platform-iOS%2015%2B-black?style=for-the-badge&logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift-orange?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Build-Bazel-43A047?style=for-the-badge&logo=bazel&logoColor=white" alt="Bazel">
  <img src="https://img.shields.io/github/stars/reekeer/WinterGram?style=for-the-badge&logo=github&logoColor=white" alt="Stars">
  <img src="https://img.shields.io/github/last-commit/reekeer/WinterGram?style=for-the-badge&logo=github&logoColor=white" alt="Last Commit">
</p>

---

**WinterGram** brings the most-loved AyuGram features to iOS with a clean, Material-inspired interface, a configurable **Liquid Glass** appearance, and a single dedicated settings tab where everything lives. It speaks both the standard `tg://` deep links and its own `wnt://` scheme.

---

## ✨ Features

### 👻 Privacy & Ghost Mode
- **Ghost Mode**: don't send read receipts, typing/upload status, or online presence — toggle it all at once.
- **Send without sound**: never / only in Ghost Mode / always.
- **Story ghost**: view stories without marking them seen, with an optional confirmation prompt.
- **Mark read after action**, **go offline after going online**, and per-toggle locks.

### 🗂 History & Recovery
- **Save deleted messages**: keep messages locally even after the other side deletes them.
- **Edit history**: store every revision of a message and browse it.
- **Semi-transparent deleted markers** and a customizable deleted / edited mark.

### 🧊 Hidden Archive ("AАrchive")
- Stash chats into a **separate, settings-only archive** — no notifications, no badge.
- Optional **auto-mark-read** for everything sent to the stash.

### 🛡️ Anti-Features
- **Disable ads** (sponsored messages).
- **Local Telegram Premium** — unlock Premium-gated UI locally.
- **Shadow ban** — silently hide a user's messages from your view.
- **Hide / disable stories**, **hide Premium statuses**, **disable open-link warning**.

### 💬 Chat Conveniences
- **Sticker / GIF / voice send confirmations**.
- **Message seconds** in timestamps and **peer ID** display (Telegram or Bot API form).
- **Message translation** with a selectable provider (Telegram / Google / Yandex / system).
- **WebView platform spoofing** (auto / iOS / Android / macOS / desktop) and taller WebViews.

### 🎨 Appearance & Customization
- **Liquid Glass** — frosted, translucent surfaces across the chat list, navigation, and tab bar, with **on/off toggle**, adjustable **transparency**, **blur radius**, **tint**, and per-surface application.
- **Material Design** switches and controls.
- **Avatar corner radius** (round → squircle → square) and **message bubble radius**, with optional single-corner mode.
- **Custom fonts** (UI + monospace).
- **App icons**, including the bundled WinterGram dark icon, plus **AyuGram / exteraGram icon-pack compatibility**.
- **Custom emoji** support, with an option to show only your added emoji & stickers.

---

## 🔗 Deep Links

WinterGram registers and resolves two URL schemes — anything that works with `tg://` works with `wnt://`:

```
tg://resolve?domain=durov
wnt://resolve?domain=durov
```

`wnt://` links are normalized to the standard resolver at the entry point, so they route through exactly the same handling as native Telegram links.

---

## 🚀 Build

WinterGram builds with the standard Telegram-iOS toolchain (Bazel via the `Make.py` wrapper) on **macOS with Xcode**.

```sh
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/appstore-configuration.json \
  --gitCodesigningRepository <your-codesigning-repo> \
  --gitCodesigningType development --gitCodesigningUseCurrent \
  --buildNumber=1 --configuration=debug_sim_arm64
```

See [`docs/wintergram-features.md`](docs/wintergram-features.md) for the feature → implementation map and the project's architecture notes.

---

## ⚙️ Configuration

All WinterGram options live in a single settings store (`WinterGramSettings`), persisted with the app's shared-data system and exposed through reactive signals. There is one dedicated **WinterGram** tab in Settings — no scattered toggles.

---

## 🗂 Structure

```
WinterGram/
├── Telegram/                ← App entry points and extensions
├── submodules/              ← Feature libraries (Swift / Obj-C)
│   └── TelegramUIPreferences/
│       └── Sources/WinterGramSettings.swift   ← all WinterGram options
├── branding/                ← WinterGram icons and brand assets
├── docs/                    ← Architecture and feature documentation
├── build-system/            ← Bazel build wrapper (Make.py)
└── README.md
```

---

## 🤝 Contributing

Contributions are welcome. WinterGram is maintained by [**IMDelewer**](https://github.com/IMDelewer) and [**salenyo**](https://github.com/salenyo) under the [reekeer](https://github.com/reekeer) organization. See [`MAINTAINERS.md`](MAINTAINERS.md).

---

<p align="center">
  Built on Telegram-iOS · inspired by AyuGram
</p>

<p align="center"><sub><a href="LICENSE">GPLv2</a> © reekeer</sub></p>
