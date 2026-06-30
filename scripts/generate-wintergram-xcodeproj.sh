#!/bin/bash
# Generate a WinterGram Xcode project configured for your Apple Developer Team.

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="build-system/wintergram-development-configuration.json"
BUNDLE_ID="${WINTERGRAM_BUNDLE_ID:-com.reekeer.wintergram}"
TEAM_ID="${WINTERGRAM_TEAM_ID:-}"
API_ID="${WINTERGRAM_API_ID:-2040}"
API_HASH="${WINTERGRAM_API_HASH:-b18441a1ff607e10a989891a5462e627}"

usage() {
    cat <<EOF
Generate WinterGram.xcodeproj with your signing settings.

Usage:
  $0 --team-id TEAMID [--bundle-id com.reekeer.wintergram] [--api-id ID --api-hash HASH]

Environment variables are also supported:
  WINTERGRAM_TEAM_ID, WINTERGRAM_BUNDLE_ID, WINTERGRAM_API_ID, WINTERGRAM_API_HASH

Example:
  $0 --team-id ABCDE12345 --bundle-id com.reekeer.wintergram
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --team-id)
            TEAM_ID="${2:-}"
            shift 2
            ;;
        --bundle-id)
            BUNDLE_ID="${2:-}"
            shift 2
            ;;
        --api-id)
            API_ID="${2:-}"
            shift 2
            ;;
        --api-hash)
            API_HASH="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$TEAM_ID" ]; then
    echo "ERROR: --team-id is required." >&2
    echo "Find it in Xcode -> Settings -> Accounts -> your Apple ID -> Team ID." >&2
    exit 1
fi

python3 - "$CONFIG" "$BUNDLE_ID" "$TEAM_ID" "$API_ID" "$API_HASH" <<'PY'
import json
import sys

path, bundle_id, team_id, api_id, api_hash = sys.argv[1:]

with open(path) as f:
    data = json.load(f)

data["bundle_id"] = bundle_id
data["team_id"] = team_id
data["api_id"] = api_id
data["api_hash"] = api_hash
data["app_specific_url_scheme"] = "wnt"
data["enable_siri"] = False
data["enable_icloud"] = False

with open(path, "w") as f:
    json.dump(data, f, indent="\t")
    f.write("\n")
PY

echo "==> Wrote $CONFIG"
echo "    bundle_id: $BUNDLE_ID"
echo "    team_id:   $TEAM_ID"

python3 build-system/Make/Make.py --overrideXcodeVersion \
    --cacheDir "$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath "$CONFIG" \
    --xcodeManagedCodesigning

echo
echo "==> Generated WinterGram.xcodeproj"
