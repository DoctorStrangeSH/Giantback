# UI icons

Store approved UI icons and collection thumbnails here, grouped by feature (for example, `items/`, `companions/`, `buildings/`, `biomes/`).

Use transparent PNG for raster UI artwork unless a specific Roblox-compatible alternative is documented. Keep source/editable artwork separate from optimized runtime exports.

## Production companion portraits

- Use the in-game imported hero model in a Roblox `ViewportFrame` only after the Studio approval flags and runtime rig checks pass.
- Never use the fallback blockout as a finished portrait or mark an art brief complete because a viewport can render it.
- For companions without an approved hero model, use a deliberately neutral discovery silhouette or an individually authored 2D portrait; do not recycle one creature icon across unrelated pets.
- The selected pet's preview should be isolated to one `WorldModel` and released when the journal entry is rebuilt.
- Keep source art and optimized runtime exports separate. Record art approval in the corresponding source-model brief.

