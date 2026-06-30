#!/usr/bin/env python3
"""Validate and optionally preview a WinterGram badge manifest."""

import argparse
import json
import math
import os
import re
import sys

ANIMATION_TYPES = {"none", "rotate", "blink", "pulse", "bounce", "shake", "lottie"}
DIRECTIONS = {"cw", "ccw"}
TINT_RE = re.compile(r"^(theme|none|#[0-9a-fA-F]{6})$")
MAX_BADGES = 64
MAX_LAYERS = 16
LOTTIE_EXTS = (".tgs", ".json")
RASTER_EXTS = (".png", ".jpg", ".jpeg")


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, path, msg):
        self.errors.append(f"{path}: {msg}")

    def warn(self, path, msg):
        self.warnings.append(f"{path}: {msg}")

    def ok(self):
        return not self.errors


def is_number(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def is_int(v):
    return isinstance(v, int) and not isinstance(v, bool)


def validate(manifest, manifest_dir, report):
    if not isinstance(manifest, dict):
        report.error("$", "manifest must be a JSON object")
        return

    if "version" not in manifest:
        report.error("$", 'missing required "version"')
    elif not is_int(manifest["version"]) or manifest["version"] < 0:
        report.error("$.version", "must be an integer >= 0")

    canvas = manifest.get("canvas", 1024)
    if not is_number(canvas) or canvas <= 0:
        report.error("$.canvas", "must be a positive number")
        canvas = 1024

    badges = manifest.get("badges")
    if badges is None:
        report.error("$", 'missing required "badges"')
        return
    if not isinstance(badges, list):
        report.error("$.badges", "must be an array")
        return
    if len(badges) > MAX_BADGES:
        report.warn("$.badges", f"{len(badges)} badges; client caps at {MAX_BADGES}")

    seen_ids = set()
    for i, badge in enumerate(badges):
        bpath = f"$.badges[{i}]"
        if not isinstance(badge, dict):
            report.error(bpath, "must be an object")
            continue

        bid = badge.get("id")
        if not isinstance(bid, str) or not bid:
            report.error(f"{bpath}.id", "must be a non-empty string")
        else:
            if bid in seen_ids:
                report.error(f"{bpath}.id", f'duplicate badge id "{bid}"')
            seen_ids.add(bid)

        if "priority" in badge and not is_int(badge["priority"]):
            report.error(f"{bpath}.priority", "must be an integer")

        if "description" in badge and not isinstance(badge.get("description"), str):
            report.error(f"{bpath}.description", "must be a string")

        peers = badge.get("peers")
        if not isinstance(peers, dict):
            report.error(f"{bpath}.peers", "must be an object")
        else:
            for key in ("users", "channels"):
                vals = peers.get(key, [])
                if not isinstance(vals, list) or not all(is_int(v) for v in vals):
                    report.error(f"{bpath}.peers.{key}", "must be an array of integers")
            if not peers.get("users") and not peers.get("channels"):
                report.warn(f"{bpath}.peers", "no users or channels; badge will never match")

        layers = badge.get("layers")
        if not isinstance(layers, list) or not layers:
            report.error(f"{bpath}.layers", "must be a non-empty array")
            continue
        if len(layers) > MAX_LAYERS:
            report.warn(f"{bpath}.layers", f"{len(layers)} layers; client caps at {MAX_LAYERS}")

        for j, layer in enumerate(layers):
            validate_layer(layer, f"{bpath}.layers[{j}]", canvas, manifest_dir, report)


def validate_layer(layer, path, canvas, manifest_dir, report):
    if not isinstance(layer, dict):
        report.error(path, "must be an object")
        return

    source = layer.get("source")
    if not isinstance(source, str) or not source:
        report.error(f"{path}.source", "must be a non-empty string")
        source = ""

    lowered = source.lower()
    is_lottie = lowered.endswith(LOTTIE_EXTS)
    if source and not is_lottie and not lowered.endswith(RASTER_EXTS):
        report.warn(f"{path}.source", "unrecognised extension (expected .png/.jpg or .tgs/.json)")

    for key in ("x", "y", "width", "height"):
        if key in layer and not is_number(layer[key]):
            report.error(f"{path}.{key}", "must be a number")
    for key in ("width", "height"):
        if is_number(layer.get(key)) and layer[key] <= 0:
            report.error(f"{path}.{key}", "must be > 0")

    x, y = layer.get("x", 0), layer.get("y", 0)
    w, h = layer.get("width", 0), layer.get("height", 0)
    if all(is_number(v) for v in (x, y, w, h)):
        if x < 0 or y < 0 or x + w > canvas or y + h > canvas:
            report.warn(path, f"layer rect ({x},{y},{w},{h}) extends outside the {canvas} canvas")

    tint = layer.get("tint")
    if tint is not None and (not isinstance(tint, str) or not TINT_RE.match(tint)):
        report.error(f"{path}.tint", 'must be "theme", "none", or "#RRGGBB"')

    anim = layer.get("animation")
    if anim is not None:
        validate_animation(anim, f"{path}.animation", is_lottie, report)

    # Asset existence (best-effort, for path-style sources).
    if source and ("/" in source or "." in source):
        asset_path = os.path.join(manifest_dir, source)
        if not os.path.isfile(asset_path):
            report.warn(f"{path}.source", f'asset not found: "{source}"')


def validate_animation(anim, path, is_lottie, report):
    if not isinstance(anim, dict):
        report.error(path, "must be an object")
        return
    atype = anim.get("type")
    if atype is not None and atype not in ANIMATION_TYPES:
        report.warn(f"{path}.type", f'unknown type "{atype}"; client treats it as "none"')
    if is_lottie and atype not in (None, "lottie", "none"):
        report.warn(path, "ignored for Lottie sources (the .tgs/.json plays itself)")
    if "duration" in anim and (not is_number(anim["duration"]) or anim["duration"] <= 0):
        report.error(f"{path}.duration", "must be a positive number")
    if "loop" in anim and not isinstance(anim["loop"], bool):
        report.error(f"{path}.loop", "must be a boolean")
    if "direction" in anim and anim["direction"] not in DIRECTIONS:
        report.error(f"{path}.direction", 'must be "cw" or "ccw"')
    if "amplitude" in anim and (not is_number(anim["amplitude"]) or anim["amplitude"] < 0):
        report.error(f"{path}.amplitude", "must be a number >= 0")


def try_jsonschema(manifest, schema_path, report):
    try:
        import jsonschema
    except ImportError:
        return
    try:
        with open(schema_path, "r", encoding="utf-8") as f:
            schema = json.load(f)
    except OSError:
        return
    validator = jsonschema.Draft7Validator(schema)
    for err in sorted(validator.iter_errors(manifest), key=lambda e: list(e.path)):
        loc = "$" + "".join(f"[{p}]" if isinstance(p, int) else f".{p}" for p in err.path)
        report.error(loc, f"[schema] {err.message}")


# ---------------------------------------------------------------------------
# Preview (GIF) generation
# ---------------------------------------------------------------------------

def parse_hex(color):
    color = color.lstrip("#")
    return (int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16))


def tint_layer(img, tint, accent_rgb):
    from PIL import Image
    img = img.convert("RGBA")
    if tint in (None, "none"):
        return img
    rgb = accent_rgb if tint == "theme" else parse_hex(tint)
    solid = Image.new("RGBA", img.size, rgb + (0,))
    solid.putalpha(img.split()[3])
    solid.paste(Image.new("RGBA", img.size, rgb + (255,)), (0, 0), img.split()[3])
    return solid


def render_badge_gif(badge, canvas, manifest_dir, out_path, size, fps, bg, accent_rgb):
    from PIL import Image

    layers = []
    for layer in badge["layers"]:
        source = layer.get("source", "")
        if source.lower().endswith(LOTTIE_EXTS):
            print(f"    note: Lottie layer '{source}' shown as a static frame in the preview")
        asset = os.path.join(manifest_dir, source)
        if not os.path.isfile(asset):
            print(f"    skip: missing asset '{source}'")
            continue
        try:
            base = Image.open(asset).convert("RGBA")
        except Exception as exc:  # noqa: BLE001
            print(f"    skip: cannot open '{source}': {exc}")
            continue
        lw = max(1, int(round(layer.get("width", canvas) / canvas * size)))
        lh = max(1, int(round(layer.get("height", canvas) / canvas * size)))
        base = base.resize((lw, lh), Image.LANCZOS)
        base = tint_layer(base, layer.get("tint"), accent_rgb)
        anim = layer.get("animation", {}) or {}
        layers.append({
            "img": base,
            "x": layer.get("x", 0) / canvas * size,
            "y": layer.get("y", 0) / canvas * size,
            "w": lw,
            "h": lh,
            "type": anim.get("type", "none"),
            "duration": anim.get("duration", 1.0) or 1.0,
            "cw": anim.get("direction", "cw") != "ccw",
            "amplitude": anim.get("amplitude", 0.1),
            "is_lottie": source.lower().endswith(LOTTIE_EXTS),
        })

    if not layers:
        print("    skip: no renderable layers")
        return False

    durations = [l["duration"] for l in layers if l["type"] in ("rotate", "blink", "pulse", "bounce", "shake") and not l["is_lottie"]]
    loop_seconds = max(durations) if durations else 2.0
    frame_count = max(1, min(120, int(round(loop_seconds * fps))))

    transparent = (bg == "none")
    bg_rgba = (0, 0, 0, 0) if transparent else (parse_hex(bg) + (255,))

    frames = []
    for f in range(frame_count):
        t = (f / frame_count) * loop_seconds
        canvas_img = Image.new("RGBA", (size, size), bg_rgba)
        for l in layers:
            frame_img = l["img"]
            ox, oy = l["x"], l["y"]
            cycles = max(1, round(loop_seconds / l["duration"])) if l["duration"] else 1
            phase = (t / loop_seconds) * cycles  # whole cycles per loop -> seamless
            angle = 2.0 * math.pi * phase

            if l["is_lottie"] or l["type"] in ("none",):
                pass
            elif l["type"] == "rotate":
                deg = (phase * 360.0) % 360.0
                frame_img = frame_img.rotate(-deg if l["cw"] else deg, resample=Image.BICUBIC, expand=False)
            elif l["type"] == "blink":
                factor = 0.35 + 0.65 * (0.5 + 0.5 * math.cos(angle))
                frame_img = apply_alpha(frame_img, factor)
            elif l["type"] == "pulse":
                scale = 1.0 + l["amplitude"] * math.sin(angle)
                frame_img, ox, oy = scaled(frame_img, scale, ox, oy, l["w"], l["h"])
            elif l["type"] == "bounce":
                oy = oy - l["amplitude"] * l["h"] * abs(math.sin(angle))
            elif l["type"] == "shake":
                ox = ox + l["amplitude"] * l["w"] * math.sin(2.0 * angle)

            canvas_img.alpha_composite(frame_img, (int(round(ox)), int(round(oy))))
        frames.append(canvas_img)

    save_gif(frames, out_path, fps, transparent)
    print(f"    wrote {out_path} ({frame_count} frames @ {fps}fps, loop {loop_seconds:.1f}s)")
    return True


def apply_alpha(img, factor):
    from PIL import Image
    alpha = img.split()[3].point(lambda a: int(a * max(0.0, min(1.0, factor))))
    out = img.copy()
    out.putalpha(alpha)
    return out


def scaled(img, scale, ox, oy, w, h):
    from PIL import Image
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    resized = img.resize((nw, nh), Image.LANCZOS)
    return resized, ox - (nw - w) / 2.0, oy - (nh - h) / 2.0


def save_gif(frames, out_path, fps, transparent):
    from PIL import Image
    duration_ms = int(round(1000.0 / fps))
    if transparent:
        conv = [f.convert("P", palette=Image.ADAPTIVE, colors=255) for f in frames]
        conv[0].save(out_path, save_all=True, append_images=conv[1:], loop=0,
                     duration=duration_ms, disposal=2, transparency=255)
    else:
        conv = [f.convert("RGB") for f in frames]
        conv[0].save(out_path, save_all=True, append_images=conv[1:], loop=0,
                     duration=duration_ms, disposal=2)


def run_preview(manifest, manifest_dir, args):
    try:
        import PIL  # noqa: F401
    except ImportError:
        print("\n--preview needs Pillow. Install it with: pip install Pillow", file=sys.stderr)
        return 1
    out_dir = args.out or manifest_dir
    os.makedirs(out_dir, exist_ok=True)
    canvas = manifest.get("canvas", 1024)
    accent_rgb = parse_hex(args.accent)
    any_done = False
    print("\nGenerating previews:")
    for badge in manifest.get("badges", []):
        bid = badge.get("id", "badge")
        if args.badge and bid != args.badge:
            continue
        out_path = os.path.join(out_dir, f"preview_{bid}.gif")
        print(f"  badge '{bid}':")
        if render_badge_gif(badge, canvas, manifest_dir, out_path, args.size, args.fps, args.bg, accent_rgb):
            any_done = True
    if args.badge and not any_done:
        print(f"  no badge with id '{args.badge}'", file=sys.stderr)
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description="Validate (and optionally preview) a WinterGram badge manifest.")
    parser.add_argument("manifest", nargs="?", default=".wintergram/icons/manifest.json")
    parser.add_argument("--schema", default=None)
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--badge", default=None)
    parser.add_argument("--size", type=int, default=256)
    parser.add_argument("--fps", type=int, default=30)
    parser.add_argument("--bg", default="#1C1C1E")
    parser.add_argument("--accent", default="#3478F6")
    parser.add_argument("--out", default=None)
    args = parser.parse_args()

    try:
        with open(args.manifest, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except OSError as exc:
        print(f"error: cannot read manifest: {exc}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as exc:
        print(f"error: invalid JSON: {exc}", file=sys.stderr)
        return 2

    manifest_dir = os.path.dirname(os.path.abspath(args.manifest))
    schema_path = args.schema or os.path.join(manifest_dir, "manifest.schema.json")

    report = Report()
    validate(manifest, manifest_dir, report)
    try_jsonschema(manifest, schema_path, report)

    for w in report.warnings:
        print(f"warning  {w}")
    for e in report.errors:
        print(f"error    {e}")

    if report.ok():
        n = len(manifest.get("badges", []))
        print(f"OK: manifest valid ({n} badge(s)).")
    else:
        print(f"\nFAILED: {len(report.errors)} error(s), {len(report.warnings)} warning(s).")
        return 1

    if args.preview:
        return run_preview(manifest, manifest_dir, args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
