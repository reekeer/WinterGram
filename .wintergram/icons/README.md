# WinterGram dynamic badges

Profile badges are data-driven from this folder. The app fetches `manifest.json`
(and the referenced assets) from GitHub on a timer and recomposes badges **without an
app update**. Offline / before the first fetch, a bundled fallback manifest is used.

## Files
- `manifest.json` - the live manifest (see `manifest.schema.json` for the full schema).
- `manifest.schema.json` - JSON Schema (draft-07). Editors that honour the `$schema`
  key in `manifest.json` will autocomplete and validate as you type.
- `<badge>/...` — layer assets (`.png`/`.jpg` rasters, or `.tgs`/`.json` Lottie).

## A badge in one glance
A badge is a stack of layers on a `canvas` (default 1024) coordinate space:

```json
{
  "name": "backplate",
  "source": "developer/backplate.png",
  "x": 0, "y": 0, "width": 1024, "height": 1024,
  "tint": "theme",
  "animation": { "type": "rotate", "duration": 8.0, "direction": "cw", "loop": true }
}
```

- `source` — path under `.wintergram/icons/`. `.png/.jpg` → raster layer; `.tgs/.json`
  → native Lottie layer (then `animation` is ignored; the Lottie plays itself).
- `tint` — `"theme"` (theme accent), `"#RRGGBB"` (fixed), or `"none"` (original colours).
- `animation.type` — `none | rotate | blink | pulse | bounce | shake | lottie`.
- `peers` — raw int64 ids; for channels use the part after the `-100` prefix
  (e.g. `-1003999337820` → `3999337820`). Highest `priority` wins on overlap.

## Validate / preview before pushing
```sh
# validate structure, tints, animations, asset existence
scripts/wintergram-badge-tool.py .wintergram/icons/manifest.json

# also render an animated GIF per badge (needs: pip install Pillow)
scripts/wintergram-badge-tool.py .wintergram/icons/manifest.json --preview
```
Useful flags: `--badge <id>`, `--size 256`, `--fps 30`, `--bg "#1C1C1E"`,
`--accent "#3478F6"` (colour used for `tint: "theme"` in the preview), `--out DIR`.

Bump `version` on every change so clients pick up the update.
