# WinterGram

<p align="center">
  <img src="branding/icon-app-light.png" width="112" height="112" alt="WinterGram white icon">
</p>

<p align="center">
  <strong>Privacy-focused Telegram client for iOS</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv2-green?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/Version-1.1-blue?style=flat-square" alt="Version 1.1">
  <img src="https://img.shields.io/badge/Platform-iOS%2015%2B-black?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift-orange?style=flat-square" alt="Swift">
  <img src="https://img.shields.io/badge/Build-Bazel-43A047?style=flat-square" alt="Bazel">
</p>

WinterGram (Wnt) is an independent iOS client for Telegram. It keeps the familiar Telegram experience and adds a dedicated **WinterGram** settings tab where privacy tools, history recovery, appearance controls, and other enhancements live in one place.

The app speaks both `tg://` deep links and its own `wnt://` scheme.

---

## Download

Prebuilt unsigned IPAs are published on the [Releases](../../releases) page. Install with [AltStore](https://altstore.io), [SideStore](https://sidestore.io), or another sideloading tool.

WinterGram is not distributed on the App Store. Free Apple IDs must re-sign the app every 7 days; AltStore and SideStore can automate this.

---

## Features

WinterGram adds Ghost Mode, saved deleted messages, edit history, a hidden archive, local Premium UI, ad removal, Liquid Glass appearance, spoofing, chat conveniences, and more.

A complete, structured feature list is in [`docs/FEATURES.md`](docs/FEATURES.md).

Developer implementation notes: [`docs/wintergram-features.md`](docs/wintergram-features.md).

---

## Quick Start (build from source)

**Requirements:** macOS, Xcode, Python 3, ~60 GB free disk space.

```sh
git clone --recursive https://github.com/reekeer/WinterGram.git
cd WinterGram
cp build-system/wintergram-development-configuration.example.json \
   build-system/wintergram-development-configuration.json
# Edit the JSON: api_id, api_hash, bundle_id, team_id
./scripts/build-wintergram.sh sim
```

The simulator IPA lands in `build/WinterGram-Simulator.ipa`. Build straight into a running Simulator with `./scripts/build-wintergram.sh --install` (add `--run` to launch it). Full instructions (device builds, signing, AltStore): [`docs/wintergram-setup.md`](docs/wintergram-setup.md).

---

## Configuration

All WinterGram options are stored in `WinterGramSettings` and exposed through the WinterGram tab in Settings. English UI strings ship in `en.lproj`; Russian translations are seeded in `submodules/TelegramPresentationData/Sources/WinterGramStrings.swift`.

---

## Project Layout

```
WinterGram/
├── Telegram/           App entry, extensions, icons, xcconfig
├── submodules/         Feature libraries (Swift / Obj-C)
├── branding/           Source art: app-icon PNGs (wnt-app-icon-*.png) + badge/snowflake shapes
├── docs/               Setup guide, feature list, architecture notes
├── build-system/       Bazel wrapper (Make.py) and configs
└── scripts/            Build + tooling
    ├── build-wintergram.sh    Convenience build script (sim / sideload / livecontainer)
    └── generate-app-icons.sh  Regenerate every app icon from branding/wnt-app-icon-*.png
```

---

## Deep Links

Anything that works with `tg://` also works with `wnt://`:

```
tg://resolve?domain=durov
wnt://resolve?domain=durov
wnt://wintergram/ghost
```

`wnt://` URLs are normalized to `tg://` at the app entry point.

---

## Contributing

Maintainers: [**IMDelewer**](https://github.com/IMDelewer), [**salenyo**](https://github.com/salenyo) under the [reekeer](https://github.com/reekeer) organization. See [`MAINTAINERS.md`](MAINTAINERS.md).

---

<p align="center"><sub><a href="LICENSE">GPLv2</a> &copy; reekeer</sub></p>
