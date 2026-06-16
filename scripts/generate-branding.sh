#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1" >&2; exit 1; }
}

require_cmd sips
require_cmd python3

BRANDING_DIR="branding"
ALTICON_BASE="Telegram/Telegram-iOS"
IMAGESET_BASE="Telegram/Telegram-iOS/AppIcons.xcassets"
DEFAULT_ASSET_BASE="Telegram/Telegram-iOS/DefaultAppIcon.xcassets"
PRIMARY_APPICONSET="$DEFAULT_ASSET_BASE/WinterGramDarkIcon.appiconset"

resize_square() {
    sips -s format png -z "$3" "$3" "$1" --out "$2" >/dev/null
}

resize_rect() {
    sips -s format png -z "$4" "$3" "$1" --out "$2" >/dev/null
}

capitalize_words() {
    python3 - "$1" <<'PY'
import re, sys
value = sys.argv[1]
print("".join(part[:1].upper() + part[1:] for part in re.split(r"[-_]+", value) if part))
PY
}

write_imageset_contents() {
    local dir="$1" name="$2"
    cat > "$dir/Contents.json" <<EOF
{
  "images" : [
    { "idiom" : "universal", "scale" : "1x" },
    { "filename" : "$name@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "$name@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
}

generate_alticon() {
    local src="$1" setname="$2" dir="$ALTICON_BASE/${setname}.alticon"
    mkdir -p "$dir"
    resize_square "$src" "$dir/${setname}@2x.png" 120
    resize_square "$src" "$dir/${setname}@3x.png" 180
    resize_square "$src" "$dir/${setname}Ipad.png" 76
    resize_square "$src" "$dir/${setname}Ipad@2x.png" 152
    resize_square "$src" "$dir/${setname}LargeIpad@2x.png" 167
    resize_square "$src" "$dir/${setname}NotificationIcon.png" 20
    resize_square "$src" "$dir/${setname}NotificationIcon@2x.png" 40
    resize_square "$src" "$dir/${setname}NotificationIcon@3x.png" 60
}

generate_icon_imageset() {
    local src="$1" setname="$2" dir="$IMAGESET_BASE/${setname}.imageset"
    mkdir -p "$dir"
    resize_square "$src" "$dir/${setname}@2x.png" 120
    resize_square "$src" "$dir/${setname}@3x.png" 180
    write_imageset_contents "$dir" "$setname"
}

generate_primary_appiconset() {
    local src="$1"
    mkdir -p "$PRIMARY_APPICONSET"
    for size in 20 29 40 58 60 80 87 120 152 167 180 1024; do
        resize_square "$src" "$PRIMARY_APPICONSET/Icon-${size}.png" "$size"
    done
}

generate_banner_imageset() {
    local src="$1" asset="$2" dir="$DEFAULT_ASSET_BASE/${asset}.imageset"
    mkdir -p "$dir"
    resize_rect "$src" "$dir/${asset}@2x.png" 1034 250
    resize_rect "$src" "$dir/${asset}@3x.png" 1551 375
    write_imageset_contents "$dir" "$asset"
}

shopt -s nullglob
icon_sources=("$BRANDING_DIR"/icon-app-*.png)
banner_sources=("$BRANDING_DIR"/banner-*.png)

if [ "${#icon_sources[@]}" -eq 0 ]; then
    echo "ERROR: no app icons found. Add PNGs named branding/icon-app-<name>.png" >&2
    exit 1
fi

wintergram_icons=()
for src in "${icon_sources[@]}"; do
    base="$(basename "$src" .png)"
    variant="${base#icon-app-}"
    setname="WinterGram$(capitalize_words "$variant")"
    wintergram_icons+=("$setname")
    echo "==> icon $setname from $src"
    generate_alticon "$src" "$setname"
    generate_icon_imageset "$src" "$setname"
    if [ "$variant" = "dark" ]; then
        generate_primary_appiconset "$src"
    fi
done

banner_assets=()
for src in "${banner_sources[@]}"; do
    base="$(basename "$src" .png)"
    variant="${base#banner-}"
    if [ "$variant" = "wintergram" ]; then
        asset="WntGramBanner"
    else
        asset="WntGramBanner$(capitalize_words "$variant")"
    fi
    banner_assets+=("$asset")
    echo "==> banner $asset from $src"
    generate_banner_imageset "$src" "$asset"
done

python3 - "${wintergram_icons[@]}" <<'PY'
import pathlib, re, sys
icons = sys.argv[1:]

build = pathlib.Path("Telegram/BUILD")
text = build.read_text()
match = re.search(r"alternate_icon_folders = \[\n(.*?)\n\]", text, re.S)
if match:
    existing = re.findall(r'"([^"]+)"', match.group(1))
    non_wintergram = [name for name in existing if not name.startswith("WinterGram") and pathlib.Path(f"Telegram/Telegram-iOS/{name}.alticon").is_dir()]
    names = sorted(non_wintergram + icons)
    block = "alternate_icon_folders = [\n" + "".join(f'    "{name}",\n' for name in names) + "]"
    text = text[:match.start()] + block + text[match.end():]
    build.write_text(text)

app_delegate = pathlib.Path("submodules/TelegramUI/Sources/AppDelegate.swift")
text = app_delegate.read_text()
pattern = r'var icons = \[\n(.*?)PresentationAppIcon\(name: "BlueIcon"'
match = re.search(pattern, text, re.S)
if match:
    wintergram_lines = "".join(f'                    PresentationAppIcon(name: "{name}", imageName: "{name}"),\n' for name in icons)
    replacement = "var icons = [\n" + wintergram_lines + '                    PresentationAppIcon(name: "BlueIcon"'
    text = text[:match.start()] + replacement + text[match.end():]
    app_delegate.write_text(text)
PY

echo
echo "==> Generated WinterGram icons: ${wintergram_icons[*]}"
if [ "${#banner_assets[@]}" -gt 0 ]; then
    echo "==> Generated banners: ${banner_assets[*]}"
fi
