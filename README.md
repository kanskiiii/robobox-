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

Run from the repository root with Node.js 24 and Blender 4.5. Blender writes the packed source file and the inspection and game-mesh review renders.

```sh
node assets/source/geometry/export-sb50.mjs --distance
node assets/source/geometry/export-sb50.mjs
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/export-components.py
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py -- --source-only
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py -- --game
```

## Studio install

The installer targets a place with Claude's SB50 vehicle configuration, Units module and AssetContract v1. Run it in Edit through Roblox Studio MCP. Prepend a local `request` table to the contents of [install-sb50.luau](studio/install-sb50.luau) for each call.

1. Run `local request = {mode = "begin"}`.
2. For each map in `atlas.maps` in [SB50-payload.json](studio/SB50-payload.json), submit each chunk using `{mode = "mapChunk", map = "<key>", index = <1-based index>, payload = "<value>"}`.
3. Run `{mode = "finishAtlas", size = 384, counts = {baseColor = 5, metalness = 1, roughness = 1, normal = 7}}`. If the atlas is regenerated, use the current map lengths from the payload.
4. For each value in `batches`, run `{mode = "batch", payload = "<value>"}`.
5. Run `{mode = "finish", meshes = 163, components = 74, triangles = 43920}`.
6. Validate `ServerStorage.Assets.Vehicles.SB50` in Edit, start a client/server playtest, and save after stopping play.

The Studio model uses one shared, session-scoped 384 × 384 PBR atlas for its opaque mesh layers. The inspection GLB and Blender model use the 1024 × 1024 atlas. The [game mesh review](assets/previews/game-05-front-quarter.jpg) shows the actual game geometry and material maps rendered in Blender.

The installer uses Roblox DataModel-scoped mesh and image content. Studio play mode has verified replication within the running session. Use the game GLB for a Creator-owned import when durable asset IDs are required.
