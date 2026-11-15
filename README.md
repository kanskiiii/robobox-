# STREETBORN

SB50 is the starter 50 cc two-stroke supermoto for Roblox place 83653077672976. The original petrol-blue bodywork and mechanical geometry are editable in Blender and reproducible from the geometry source.

| Deliverable | Path |
| --- | --- |
| Editable Blender model | [SB50.blend](assets/source/blender/SB50.blend) |
| PBR inspection model | [SB50-inspection.glb](assets/export/vehicles/SB50-inspection.glb) |
| Roblox game mesh | [SB50-game.glb](assets/export/vehicles/SB50-game.glb) |
| Studio import package | [SB50-StudioImport.glb](assets/export/vehicles/SB50-StudioImport.glb) and [binding layout](assets/manifests/SB50-studio-import.json) |
| Service parts and alternate finishes | [Component manifest](assets/manifests/SB50-components.json) |
| Studio handoff | [Codex 1 to Claude](coordination/CODEX1_TO_CLAUDE.md) |
| Eight review views | [Review sheet](assets/previews/SB50-review.png) |

## Rebuild

Run from the repository root with Node.js 24 and Blender 4.5. Blender writes the packed source file and the inspection and game-mesh review renders.

```sh
node assets/source/geometry/export-sb50.mjs --distance
node assets/source/geometry/export-studio-import.mjs
node assets/source/geometry/export-sb50.mjs
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/export-components.py
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py -- --source-only
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py
blender -b -t 6 --python-exit-code 1 -P assets/source/blender/review.py -- --game
```

## Preview install in Studio

The installer targets a place with Claude's SB50 vehicle configuration, Units module and AssetContract v1. Run it in Edit through Roblox Studio MCP. Prepend a local `request` table to the contents of [install-sb50.luau](studio/install-sb50.luau) for each call.

1. Run `local request = {mode = "begin"}`.
2. For each map in `atlas.maps` in [SB50-payload.json](studio/SB50-payload.json), submit each chunk using `{mode = "mapChunk", map = "<key>", index = <1-based index>, payload = "<value>"}`.
3. Run `{mode = "finishAtlas", size = 384, counts = {baseColor = 5, metalness = 1, roughness = 1, normal = 7}}`. If the atlas is regenerated, use the current map lengths from the payload.
4. For each value in `batches`, run `{mode = "batch", payload = "<value>"}`.
5. Run `{mode = "finish", meshes = 163, components = 74, triangles = 43920}`.
6. Validate `ServerStorage.Assets.Vehicles.SB50` in Edit, start a client/server playtest, and save after stopping play.

The Studio model uses one shared, session-scoped 384 × 384 PBR atlas for its opaque mesh layers. The inspection GLB and Blender model use the 1024 × 1024 atlas. The [game mesh review](assets/previews/game-05-front-quarter.jpg) shows the actual game geometry and material maps rendered in Blender.

The installer uses Roblox DataModel-scoped mesh and image content. Studio play mode has verified replication within the running session. Use the workflow below for durable asset IDs.

## Persistent import in Studio

1. Open place `83653077672976` in Roblox Studio with an account authorized to upload assets for the place.
2. Use File → Import with [SB50-StudioImport.glb](assets/export/vehicles/SB50-StudioImport.glb). Enable **Upload to Roblox**, **Add to Workspace**, and **Anchored**. Leave **Merge Meshes** off. Keep the default Forward and Up axes. The binding script sets the gameplay scale and pivots.
3. Select the imported root Model in Explorer. In Edit, run [install-sb50.luau](studio/install-sb50.luau) with `local request = {mode = "begin"}`.
4. Run the same installer with `mode = "bindImport"`, `source` set to the imported Workspace Model, and `layout` set to the literal JSON from [SB50-studio-import.json](assets/manifests/SB50-studio-import.json). For example, use a Luau long string to supply the JSON.

```lua
local request = {
    mode = "bindImport",
    source = game:GetService("Selection"):Get()[1],
    layout = [====[paste SB50-studio-import.json here]====],
}
```

5. Run `local request = {mode = "finish", meshes = 163, components = 74, triangles = 43920}` to validate and install the staged rig. Remove the separate imported preview from Workspace once the installed rig is ready.
6. Save the place, reopen it in a new Studio session, and check the spawned bike in Play. Confirm the paint, metal, rubber, and tread render on the client from both sides.

The package provides one named, centred primitive for each mesh layer and includes tangent data for normal maps. The binder restores all component positions, attachment offsets, and chassis ownership. It checks the Roblox mesh and material asset references before replacing the installed model. A fixture in Studio verified the binding geometry and AssetContract; the owner-authorized import and fresh-session render are still pending. [Roblox Studio Importer](https://create.roblox.com/docs/studio/importer)
