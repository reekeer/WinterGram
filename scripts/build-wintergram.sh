#!/bin/bash
# WinterGram build wrapper.

set -euo pipefail
cd "$(dirname "$0")/.."
REPO="$(pwd)"

OUT_DIR="build"
SIDELOAD_NAME="WinterGram.ipa"
LC_NAME="WinterGram-LiveContainer.ipa"
SIM_NAME="WinterGram-Simulator.ipa"
WNT_BUNDLE_ID="dev.reekeer.wintergram"
BAZEL="./build-input/bazel-8.4.2-darwin-arm64"
DEVICE_SRC="bazel-bin/Telegram/Telegram.ipa"
_XCODE_DEV_DIR="${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null)}"
BAZEL_XCODE_ACTION_ENV="--action_env=DEVELOPER_DIR=${_XCODE_DEV_DIR} --host_action_env=DEVELOPER_DIR=${_XCODE_DEV_DIR}"
# Xcode 27 compatibility
BAZEL_SDK_COMPAT_ARGS="--features=-treat_warnings_as_errors --@build_bazel_rules_swift//swift:copt=-no-warnings-as-errors --copt=-Wno-deprecated-declarations"

MODE="all"
INSTALL_REQUESTED=0
INSTALL_DEVICE=0
INSTALL_SIM=0
RUN_APP=0
CLEAN=0
OPEN_BUILD_DIR=0
DEVICE_SELECTOR=""

usage() {
    cat <<EOF
WinterGram build wrapper

Usage:
  $0 [mode] [options]

Modes:
  all                 Build all deliverables. Default.
  sideload, device,
  ios                 Build device sideload IPA -> build/$SIDELOAD_NAME
  livecontainer, lc   Build unsigned LiveContainer IPA -> build/$LC_NAME
  sim, simulator      Build simulator IPA -> build/$SIM_NAME

Options:
  --install           Install after build. With ios/device/sideload mode, installs on a connected
                      iPhone/iPad via xcrun devicectl. With sim mode, installs into the active
                      booted Simulator. With no explicit mode, keeps the old simulator shortcut.
  --device <id|name>  Device selector for devicectl. Optional if exactly one iPhone/iPad is connected.
  --run               Launch the app after --install (implies --install).
  --clean             Remove ./build before building.
  --open-build-dir    Open ./build in Finder after build.
  -h, --help          Show this help.

Examples:
  $0 ios --install
  $0 ios --install --run
  $0 ios --install --device "Del's iPhone"
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
        all|sideload|device|ios|livecontainer|lc|sim|simulator)
            MODE="$1"
            MODE_WAS_EXPLICIT=1
            ;;
        --install)
            INSTALL_REQUESTED=1
            ;;
        --run)
            RUN_APP=1
            INSTALL_REQUESTED=1
            ;;
        --device)
            shift
            [ "$#" -gt 0 ] || die "--device requires a value"
            DEVICE_SELECTOR="$1"
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

if [ "$INSTALL_REQUESTED" -eq 1 ]; then
    case "$MODE" in
        sim|simulator)
            INSTALL_SIM=1
            ;;
        sideload|device|ios)
            INSTALL_DEVICE=1
            ;;
        all)
            if [ "$MODE_WAS_EXPLICIT" -eq 1 ]; then
                die "--install with 'all' is ambiguous. Use 'ios --install' for a device or 'sim --install' for Simulator."
            fi

            MODE="sim"
            INSTALL_SIM=1
            ;;
        livecontainer|lc)
            die "--install does not support LiveContainer IPA. Use 'ios --install' for direct device install."
            ;;
    esac
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
        --codesigningInformationPath build-system/fake-codesigning \
        --disableProvisioningProfiles \
        --disableExtensions \
        --bazelArguments="$BAZEL_XCODE_ACTION_ENV $BAZEL_SDK_COMPAT_ARGS" \
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

    if [ "$RUN_APP" -eq 1 ]; then
        [ -n "$INSTALLED_BUNDLE_ID" ] || {
            rm -rf "$TMP_DIR"
            die "could not read CFBundleIdentifier from app Info.plist"
        }

        echo "==> [Simulator] launching $INSTALLED_BUNDLE_ID ..."
        xcrun simctl launch booted "$INSTALLED_BUNDLE_ID" || true
    fi

    rm -rf "$TMP_DIR"
}

select_ios_device() {
    require_cmd xcrun

    if [ -n "$DEVICE_SELECTOR" ]; then
        echo "$DEVICE_SELECTOR"
        return 0
    fi

    local JSON_PATH
    JSON_PATH="$(mktemp)"

    if ! xcrun devicectl list devices --timeout 20 --json-output "$JSON_PATH" >/dev/null; then
        rm -f "$JSON_PATH"
        die "could not list connected devices via xcrun devicectl. Unlock the phone, trust this Mac, and try again."
    fi

    local SELECTED
    if ! SELECTED="$(python3 - "$JSON_PATH" 2>&1 <<'PY'
import json
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

devices = data.get("result", {}).get("devices", [])

def get(obj, dotted, default=""):
    current = obj
    for part in dotted.split("."):
        if not isinstance(current, dict):
            return default
        current = current.get(part)
    return current if current is not None else default

candidates = []
for device in devices:
    platform = str(get(device, "hardwareProperties.platform")).lower()
    if platform not in ("ios", "ipados"):
        continue

    identifier = (
        device.get("identifier")
        or get(device, "hardwareProperties.udid")
        or get(device, "hardwareProperties.serialNumber")
    )
    if not identifier:
        continue

    name = (
        get(device, "deviceProperties.name")
        or device.get("name")
        or get(device, "hardwareProperties.marketingName")
        or identifier
    )
    transport = get(device, "connectionProperties.transportType")
    pair_state = get(device, "connectionProperties.pairingState")
    candidates.append((str(identifier), str(name), str(transport), str(pair_state)))

if len(candidates) == 1:
    print(candidates[0][0])
    sys.exit(0)

if not candidates:
    print("no connected iPhone/iPad found by devicectl", file=sys.stderr)
else:
    print("multiple iPhone/iPad devices found; pass --device with one of these:", file=sys.stderr)
    for identifier, name, transport, pair_state in candidates:
        details = ", ".join(part for part in (transport, pair_state) if part)
        suffix = f" ({details})" if details else ""
        print(f"  {identifier}  {name}{suffix}", file=sys.stderr)

sys.exit(2)
PY
)"; then
        rm -f "$JSON_PATH"
        die "$SELECTED"
    fi

    rm -f "$JSON_PATH"
    echo "$SELECTED"
}

install_device() {
    require_cmd xcrun

    local IPA="$OUT_DIR/$SIDELOAD_NAME"
    [ -f "$IPA" ] || die "device IPA not found at $IPA"

    echo "==> [Device] preparing app for install ..."

    local TMP_DIR
    TMP_DIR="$(mktemp -d)"

    unzip -q "$IPA" -d "$TMP_DIR"

    local APP_PATH
    APP_PATH="$(find "$TMP_DIR/Payload" -maxdepth 1 -type d -name "*.app" | head -n 1)"

    [ -n "${APP_PATH:-}" ] || {
        rm -rf "$TMP_DIR"
        die "no .app found inside $IPA"
    }

    local INSTALLED_BUNDLE_ID
    INSTALLED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)"

    local DEVICE
    DEVICE="$(select_ios_device)"

    echo "==> [Device] installing $(basename "$APP_PATH") on $DEVICE ..."
    xcrun devicectl device install app --device "$DEVICE" "$APP_PATH"

    echo "==> [Device] installed: $(basename "$APP_PATH")"

    if [ "$RUN_APP" -eq 1 ]; then
        [ -n "$INSTALLED_BUNDLE_ID" ] || {
            rm -rf "$TMP_DIR"
            die "could not read CFBundleIdentifier from app Info.plist"
        }

        echo "==> [Device] launching $INSTALLED_BUNDLE_ID on $DEVICE ..."
        xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$INSTALLED_BUNDLE_ID" || true
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

    echo "==> [Device] generating fake provisioning profiles for ${WNT_BUNDLE_ID} ..."
    python3 scripts/generate-fake-profiles.py build-system/fake-codesigning-generated

    echo "==> [Device] build (debug_arm64, ${WNT_BUNDLE_ID}, extensions disabled) ..."
    python3 build-system/Make/Make.py --overrideXcodeVersion \
        --cacheDir "$HOME/telegram-bazel-cache" \
        build \
        --configurationPath build-system/wintergram-development-configuration.json \
        --codesigningInformationPath build-system/fake-codesigning-generated \
        --disableExtensions \
        --bazelArguments="$BAZEL_XCODE_ACTION_ENV $BAZEL_SDK_COMPAT_ARGS" \
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
    sideload|device|ios)
        build_device
        make_sideload
        ;;
    livecontainer|lc)
        build_device
        make_livecontainer
        ;;
    all)
        # Derive device deliverables before the simulator build overwrites the artifact.
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
    install_sim
fi

if [ "$INSTALL_DEVICE" -eq 1 ]; then
    install_device
fi

echo
echo "==> WinterGram deliverables in ./$OUT_DIR/:"
ls -1 "$OUT_DIR"/WinterGram*.ipa 2>/dev/null | sed 's#^#    #' || true

if [ "$OPEN_BUILD_DIR" -eq 1 ]; then
    open "$OUT_DIR"
fi
