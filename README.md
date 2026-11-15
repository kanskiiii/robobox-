# STREETBORN

SB50 is the starter 50 cc two-stroke supermoto for Roblox place 83653077672976. The original petrol-blue bodywork and mechanical geometry are editable in Blender and reproducible from the geometry source.

| Deliverable | Path |
| --- | --- |
| Editable Blender model | [SB50.blend](assets/source/blender/SB50.blend) |
| PBR inspection model | [SB50-inspection.glb](assets/export/vehicles/SB50-inspection.glb) |
| Roblox game mesh | [SB50-game.glb](assets/export/vehicles/SB50-game.glb) |
| Service parts and alternate finishes | [Component manifest](assets/manifests/SB50-components.json) |
| Studio handoff | [Codex 1 to Claude](coordination/CODEX1_TO_CLAUDE.md) |
| Eight review views | [Review sheet](assets/previews/SB50-review.png) |

## Rebuild

Run from the repository root with Node.js 24 and Blender 4.5. The last two commands produce the packed Blender file and review renders, respectively.

```sh
node assets/source/geometry/export-sb50.mjs --distance
node assets/source/geometry/export-sb50.mjs
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/export-components.py
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py -- --source-only
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py
```

## Studio install

The installer targets a place with Claude's SB50 vehicle configuration, Units module and AssetContract v1. Run it in Edit through Roblox Studio MCP. Prepend a local `request` table to the contents of [install-sb50.luau](studio/install-sb50.luau) for each call.

1. Run `local request = {mode = "begin"}`.
2. For every value in `batches` in [SB50-payload.json](studio/SB50-payload.json), run `local request = {mode = "batch", payload = "<value>"}`.
3. Run `local request = {mode = "finish", meshes = 159, components = 74, triangles = 46460}`.
4. Check `ServerStorage.Assets.Vehicles.SB50` in Edit and start a client/server playtest. Save the place after stopping play.

The installation uses place-embedded mesh content and Roblox materials. The inspection GLB and Blender model carry the texture atlas.
