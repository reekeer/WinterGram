#!/bin/bash
# WinterGram build wrapper — produces WinterGram-named IPAs for every install target.
# Lives in scripts/; all paths are resolved relative to the repo root (the script cd's there).
#
# Usage:
#   ./scripts/build-wintergram.sh
#   ./scripts/build-wintergram.sh all
#   ./scripts/build-wintergram.sh sideload
#   ./scripts/build-wintergram.sh livecontainer
#   ./scripts/build-wintergram.sh sim
#
# Convenience:
#   ./scripts/build-wintergram.sh --install        # build the simulator IPA and install it into the active Simulator (sim mode only)
#   ./scripts/build-wintergram.sh --install --run  # also launch the app in the active Simulator
#   ./scripts/build-wintergram.sh --clean          # remove ./build before building
#   ./scripts/build-wintergram.sh --open-build-dir # open ./build in Finder after build
#   ./scripts/build-wintergram.sh --help

set -euo pipefail
# Resolve to the repo root regardless of where the script is invoked from (it lives in scripts/).
cd "$(dirname "$0")/.."
REPO="$(pwd)"
source ~/.zshrc 2>/dev/null || true

OUT_DIR="build"
SIDELOAD_NAME="WinterGram.ipa"
LC_NAME="WinterGram-LiveContainer.ipa"
SIM_NAME="WinterGram-Simulator.ipa"
WNT_BUNDLE_ID="dev.reekeer.wintergram"
BAZEL="./build-input/bazel-8.4.2-darwin-arm64"
DEVICE_SRC="bazel-bin/Telegram/Telegram.ipa"

MODE="all"
INSTALL_SIM=0
RUN_SIM=0
CLEAN=0
OPEN_BUILD_DIR=0

usage() {
    cat <<EOF
WinterGram build wrapper

Usage:
  $0 [mode] [options]

Modes:
  all                 Build all deliverables. Default.
  sideload, device    Build device sideload IPA -> build/$SIDELOAD_NAME
  livecontainer, lc   Build unsigned LiveContainer IPA -> build/$LC_NAME
  sim, simulator      Build simulator IPA -> build/$SIM_NAME

Options:
  --install           Build the simulator IPA and install it into the active booted Simulator.
                      This forces "sim" mode (install only makes sense for the simulator).
  --run               Launch the app after --install (implies --install).
  --clean             Remove ./build before building.
  --open-build-dir    Open ./build in Finder after build.
  -h, --help          Show this help.

Examples:
  $0 --install
  $0 --install --run
  $0 sideload --clean
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

ipa_size() {
    du -h "$1" | cut -f1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

# --- args ------------------------------------------------------------------

MODE_WAS_EXPLICIT=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        all|sideload|device|livecontainer|lc|sim|simulator)
            MODE="$1"
            MODE_WAS_EXPLICIT=1
            ;;
        --install)
            INSTALL_SIM=1
            ;;
        --run)
            RUN_SIM=1
            INSTALL_SIM=1
            ;;
        --clean)
            CLEAN=1
            ;;
        --open-build-dir)
            OPEN_BUILD_DIR=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
    shift
done

# --install is simulator-only: installing a device/livecontainer IPA into a Simulator makes no
# sense, so --install always forces "sim" mode (warning if a conflicting mode was given).
if [ "$INSTALL_SIM" -eq 1 ]; then
    if [ "$MODE_WAS_EXPLICIT" -eq 1 ] && [ "$MODE" != "sim" ] && [ "$MODE" != "simulator" ]; then
        echo "==> --install is simulator-only; ignoring mode '$MODE' and building 'sim'." >&2
    fi
    MODE="sim"
fi

if [ "$CLEAN" -eq 1 ]; then
    echo "==> Cleaning ./$OUT_DIR ..."
    rm -rf "$OUT_DIR"
fi

mkdir -p "$OUT_DIR"

# --- simulator -------------------------------------------------------------

build_sim() {
    echo "==> [Simulator] build (debug_sim_arm64) ..."
    python3 build-system/Make/Make.py --overrideXcodeVersion \
        --cacheDir "$HOME/telegram-bazel-cache" \
        build \
        --configurationPath build-system/wintergram-development-configuration.json \
        --codesigningInformationPath build-system/fake-codesigning-wintergram \
        --disableExtensions \
        --buildNumber=1 --configuration=debug_sim_arm64

    [ -f "$DEVICE_SRC" ] || die "simulator artifact not found at $DEVICE_SRC"

    cp -f "$DEVICE_SRC" "$OUT_DIR/$SIM_NAME"
    echo "==> [Simulator] done: $OUT_DIR/$SIM_NAME ($(ipa_size "$OUT_DIR/$SIM_NAME"))"
}

ensure_booted_simulator() {
    require_cmd xcrun

    if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
        die "no active booted Simulator found. Open Simulator.app and boot a device first."
    fi
}

install_sim() {
    ensure_booted_simulator

    local IPA="$OUT_DIR/$SIM_NAME"
    [ -f "$IPA" ] || die "simulator IPA not found at $IPA"

    echo "==> [Simulator] installing into active booted Simulator ..."

    local TMP_DIR
    TMP_DIR="$(mktemp -d)"

    unzip -q "$IPA" -d "$TMP_DIR"

    local APP_PATH
    APP_PATH="$(find "$TMP_DIR/Payload" -maxdepth 1 -type d -name "*.app" | head -n 1)"

    [ -n "${APP_PATH:-}" ] || {
        rm -rf "$TMP_DIR"
        die "no .app found inside $IPA"
    }

    xcrun simctl install booted "$APP_PATH"

    local INSTALLED_BUNDLE_ID
    INSTALLED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)"

    echo "==> [Simulator] installed: $(basename "$APP_PATH")"

    if [ "$RUN_SIM" -eq 1 ]; then
        [ -n "$INSTALLED_BUNDLE_ID" ] || {
            rm -rf "$TMP_DIR"
            die "could not read CFBundleIdentifier from app Info.plist"
        }

        echo "==> [Simulator] launching $INSTALLED_BUNDLE_ID ..."
        xcrun simctl launch booted "$INSTALLED_BUNDLE_ID" || true
    fi

    rm -rf "$TMP_DIR"
}

# --- device build shared by sideload + livecontainer -----------------------

ensure_cert() {
    # Device builds need a codesigning identity in the keychain, even a throwaway one.
    if ! security find-certificate -c "Apple Distribution: Telegram FZ-LLC (C67CF9S4VU)" >/dev/null 2>&1; then
        echo "==> Importing throwaway signing cert into login keychain ..."
        security import build-system/fake-codesigning/certs/SelfSigned.p12 -P "" -A >/dev/null 2>&1 || true
    fi
}

build_device() {
    ensure_cert

    echo "==> [Device] build (debug_arm64, ${WNT_BUNDLE_ID}, extensions disabled) ..."
    python3 build-system/Make/Make.py --overrideXcodeVersion \
        --cacheDir "$HOME/telegram-bazel-cache" \
        build \
        --configurationPath build-system/wintergram-development-configuration.json \
        --codesigningInformationPath build-system/fake-codesigning-wintergram \
        --disableExtensions \
        --buildNumber=1 --configuration=debug_arm64

    [ -f "$DEVICE_SRC" ] || die "device artifact not found at $DEVICE_SRC"
}

make_sideload() {
    cp -f "$DEVICE_SRC" "$OUT_DIR/$SIDELOAD_NAME"
    echo "==> [Sideload] done: $OUT_DIR/$SIDELOAD_NAME ($(ipa_size "$OUT_DIR/$SIDELOAD_NAME"))"
}

make_livecontainer() {
    echo "==> [LiveContainer] repackaging unsigned ..."

    local TMP_DIR
    TMP_DIR="$(mktemp -d)"

    unzip -q "$DEVICE_SRC" -d "$TMP_DIR"

    find "$TMP_DIR/Payload/Telegram.app" -type f \( -name Telegram -o -name "*.dylib" \) -print0 2>/dev/null \
        | xargs -0 codesign --remove-signature 2>/dev/null || true

    find "$TMP_DIR/Payload/Telegram.app" -type d -name "*.framework" -print0 2>/dev/null | while IFS= read -r -d '' fw; do
        local bin
        bin="$fw/$(basename "$fw" .framework)"
        [ -f "$bin" ] && codesign --remove-signature "$bin" 2>/dev/null || true
    done

    find "$TMP_DIR" -type d \( -name _CodeSignature -o -name SC_Info \) -exec rm -rf {} + 2>/dev/null || true
    find "$TMP_DIR/Payload/Telegram.app" -name "embedded.mobileprovision" -delete 2>/dev/null || true

    rm -f "$OUT_DIR/$LC_NAME"

    local ZIP_ITEMS="Payload"
    [ -d "$TMP_DIR/SwiftSupport" ] && ZIP_ITEMS="$ZIP_ITEMS SwiftSupport"

    (
        cd "$TMP_DIR"
        zip -qr "$REPO/$OUT_DIR/$LC_NAME" $ZIP_ITEMS
    )

    rm -rf "$TMP_DIR"

    echo "==> [LiveContainer] done: $OUT_DIR/$LC_NAME ($(ipa_size "$OUT_DIR/$LC_NAME"))"
}

# --- main ------------------------------------------------------------------

case "$MODE" in
    sim|simulator)
        build_sim
        ;;
    sideload|device)
        build_device
        make_sideload
        ;;
    livecontainer|lc)
        build_device
        make_livecontainer
        ;;
    all)
        # One device build feeds BOTH device deliverables; derive them before the sim build
        # overwrites bazel-bin/Telegram/Telegram.ipa with the simulator artifact.
        build_device
        make_sideload
        make_livecontainer
        build_sim
        ;;
    *)
        die "unknown mode: $MODE"
        ;;
esac

if [ "$INSTALL_SIM" -eq 1 ]; then
    # --install forced MODE=sim above, so the simulator IPA was just built — install it.
    install_sim
fi

echo
echo "==> WinterGram deliverables in ./$OUT_DIR/:"
ls -1 "$OUT_DIR"/WinterGram*.ipa 2>/dev/null | sed 's#^#    #' || true

if [ "$OPEN_BUILD_DIR" -eq 1 ]; then
    open "$OUT_DIR"
fi