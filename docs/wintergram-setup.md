# WinterGram Build & Install Guide

This guide covers how to build WinterGram from source, run it in the iOS Simulator, install it on a physical iPhone without a paid Apple Developer Program, and sideload the resulting IPA.

## Requirements

- macOS with Xcode (the project is tested on Xcode 26.x)
- Python 3
- ~60 GB of free disk space (Bazel cache + build artifacts)
- A free Apple ID (for on-device installation)

## 1. Clone the repository

```sh
git clone --recursive https://github.com/reekeer/WinterGram.git
cd WinterGram
```

If you cloned without `--recursive`:

```sh
git submodule update --init --recursive
```

## 2. Configure build credentials

WinterGram needs a development configuration with your own credentials.

1. Copy the example file:

   ```sh
   cp build-system/wintergram-development-configuration.example.json \
      build-system/wintergram-development-configuration.json
   ```

2. Edit `build-system/wintergram-development-configuration.json`:
   - `bundle_id` — a unique bundle identifier (e.g. `dev.you.wintergram`).
   - `api_id` / `api_hash` — obtain from <https://my.telegram.org/apps>.
   - `team_id` — your Apple Developer Team ID (a 10-character string). For a free Apple ID, create an Apple Development certificate in Xcode → Settings → Accounts, then find the Team ID in Keychain Access under the certificate's **Organizational Unit** field.
   - `app_specific_url_scheme` is `wnt` by default.

> **Important:** `api_id` and `api_hash` are baked into the app at build time. You cannot change them after installation because your Telegram session is tied to the `api_id` used when logging in.

The committed example uses public test values (`api_id: 2040`). Replace them with your own before installing on a personal device.

## 3. Build an unsigned IPA

### Convenience wrapper (recommended)

`scripts/build-wintergram.sh` wraps the Bazel/Make.py invocations and emits WinterGram-named IPAs in `build/`:

```sh
./scripts/build-wintergram.sh sim            # simulator      -> build/WinterGram-Simulator.ipa
./scripts/build-wintergram.sh --install      # build sim + install into the booted Simulator (sim only)
./scripts/build-wintergram.sh --install --run # also launch it
./scripts/build-wintergram.sh sideload       # device IPA     -> build/WinterGram.ipa
./scripts/build-wintergram.sh livecontainer  # unsigned IPA   -> build/WinterGram-LiveContainer.ipa
./scripts/build-wintergram.sh all            # all of the above
```

`--clean` wipes `build/` first; `--open-build-dir` reveals the output in Finder; `--help` lists everything.

The raw commands below are equivalent if you prefer to invoke Make.py directly.

The fastest path to a device IPA is a terminal build:

```sh
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/wintergram-development-configuration.json \
  --xcodeManagedCodesigning \
  --buildNumber=1 \
  --configuration=debug_arm64
```

The finished `.ipa` is written to `bazel-bin/Telegram/`.

For a simulator build, use `debug_sim_arm64` and fake codesigning files (the Simulator does not validate signatures, but Bazel still requires provisioning profiles):

```sh
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/wintergram-development-configuration.json \
  --codesigningInformationPath build-system/fake-codesigning \
  --buildNumber=1 \
  --configuration=debug_sim_arm64
```

Add `--continueOnError` after `build` to see every error in one pass. `--xcodeManagedCodesigning` is intended for `generateProject`; for terminal builds with extensions, use `--codesigningInformationPath build-system/fake-codesigning`.

## 4. Install on a physical iPhone (free Apple ID)

### With AltStore / SideStore

1. Build a device IPA (`debug_arm64` or `release_arm64`) with your Team ID in the config.
2. Install AltStore on your phone (via AltServer on your Mac).
3. In AltStore, tap **+**, select the built `.ipa`, and let AltStore re-sign and install it.
4. A free Apple ID must re-sign the app every 7 days. AltStore and SideStore can refresh this automatically in the background.

### With Xcode directly

1. Generate the Xcode project (see below).
2. Select the **Telegram** scheme and your connected iPhone as the destination.
3. In the target's **Signing & Capabilities**, choose your Personal Team.
4. Press ⌘R. The first time, trust the developer on the device in Settings → General → VPN & Device Management.

Free provisioning profiles last 7 days and are limited to 3 apps per Apple ID. Push notifications via APNs, Siri, and iCloud are unavailable with a free account, so the dev config has `enable_siri` and `enable_icloud` disabled.

## 5. Generate an Xcode project

```sh
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  generateProject \
  --configurationPath build-system/wintergram-development-configuration.json \
  --xcodeManagedCodesigning
```

To generate a simulator-only project without provisioning profiles, add `--disableProvisioningProfiles`.

The command opens the generated `Telegram.xcodeproj` automatically. If it does not, the project is in the repository root.

## 6. Run in the Simulator

1. Open the generated `Telegram.xcodeproj`.
2. Select the **Telegram** scheme and any iPhone Simulator.
3. Press ⌘R.

The first build is slow (40–90 minutes) because WebRTC and ffmpeg are compiled from source. Incremental builds are much faster. If Xcode hangs on "build-request.json not updated yet", cancel and run again; this is a known rules_xcodeproj quirk.

## App icons

All WinterGram app-icon assets are generated from source PNGs in `branding/` by a single script:

```sh
./scripts/generate-app-icons.sh
```

Each source named `branding/wnt-app-icon-<variant>.png` (square, ≥1024×1024) becomes an alternate
icon `WinterGram<Variant>`. The two shipping icons are `wnt-app-icon-dark.png` (also the primary
home-screen icon) and `wnt-app-icon-light.png`. The script regenerates the `.alticon` folders, the
primary `WinterGramDarkIcon.appiconset`, and the in-app preview imagesets in one pass.

A brand-new variant is generated but must still be registered manually — the script prints the three
spots: `Telegram/BUILD` (`alternate_icon_folders`), `AppDelegate.getAvailableAlternateIcons()`, and the
preview-imageset mapping in `applicationBindings`.

## Repository layout

```
WinterGram/
├── Telegram/                  ← App entry point and extensions
│   ├── Telegram-iOS/          ← Info.plist, assets, xcconfig
│   ├── Share / SiriIntents / NotificationService / ...
│   └── WatchApp/              ← watchOS client snapshot
├── submodules/                ← Functionality split into Bazel modules
│   ├── TelegramUIPreferences/Sources/WinterGramSettings.swift
│   └── SettingsUI/Sources/WinterGramSettingsController.swift
├── branding/                  ← Source art: app-icon PNGs (wnt-app-icon-*.png) + badge/snowflake shapes
├── scripts/                   ← Build + tooling
│   ├── build-wintergram.sh    ← Convenience build wrapper (sim / sideload / livecontainer)
│   └── generate-app-icons.sh  ← App-icon generator (reads branding/wnt-app-icon-*.png)
├── docs/                      ← Documentation
├── build-system/              ← Bazel wrapper and configs
│   └── wintergram-development-configuration.json  ← your dev config
├── third-party/               ← External dependencies
└── Tests/                     ← Bazel test app targets
```

## Troubleshooting

- **"No .mobileprovision targets for extensions"** when using `--xcodeManagedCodesigning` in a terminal build: use `--codesigningInformationPath build-system/fake-codesigning` instead, or use `generateProject` for Xcode-managed signing.
- **Build fails on the first try:** ensure submodules are fully initialized and you have enough disk space.
- **App crashes on launch after re-signing:** make sure the `bundle_id` in your config is unique and the `team_id` matches the certificate used to sign.
