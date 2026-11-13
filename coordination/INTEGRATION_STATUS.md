# SM50 integration status

The source generator uses Node.js 24 and has no package dependencies. Run `node assets/vehicles/sm50/source/build.mjs` from the project folder to regenerate the GLB, manifest and Studio preview batches. The GLB can also be opened in Blender.

The export contains 81 component nodes and 179 material primitives, with 111,124 triangles in total. The largest component has 16,416 triangles. The generator checks finite positions, face area, solid winding and welded edge incidence, then rereads the GLB and verifies its structure and indices. Run the same command with `--distance` after building the inspection model to export the 45,348-triangle distance variant and verify its retained pivots and attachments against the inspection manifest. Runtime LOD switching and mobile performance profiling are pending.

The preview uses transient EditableMesh content. Studio's instance serializer dropped the geometry in a round-trip test. Use the local GLB for durable Roblox import. In Studio's 3D Importer, choose metres and keep Merge Meshes disabled. The model uses glTF PBR material factors. Baked texture maps are pending, and the Studio preview uses built-in materials.

The preview is in `Workspace.SM50_AssetPreview`, beside the spawn at X = 9 studs. Studio measured about 2.65 × 3.89 × 6.89 studs (X × Y × Z). The front axle is on −Z, chain drive on −X, and expansion chamber on +X. Preview images are under `assets/vehicles/sm50/previews`.

## Starter garage

Run `node assets/vehicles/sm50/source/build.mjs --garage` to regenerate the GLB, per-component manifest and Studio batches. The same geometry and binary checks apply. The export includes 45 component nodes, 94 material primitives and 42,228 triangles. The shared preview loader accepts `previewConfig` for staging this asset. The sample workshop is at `Workspace.StarterGarage_AssetPreview` with its floor centre at X = 43 studs. Collision boxes in the edit-time preview are disabled.

## Commuter scooter

Run `node assets/vehicles/sm50/source/build.mjs --scooter`. The model uses the shared metres and axes convention and contains 38 component nodes, 84 material primitives and 44,894 triangles. Studio verified 72 attachment markers and three collision proxies. The preview is at `Workspace.CommuterScooter_AssetPreview`, with the root at X = 23 studs. Runtime movement and cable flex are open.

## Rural road kit

Run `node assets/vehicles/sm50/source/build.mjs --roads`. The export has eight individually selectable modules and 5,476 triangles. The straight, turn and T-junction share a 5.6 m paved cross section. The turn requires collision derived from its arc segments or imported mesh. The manifest gives the other collision proxies and connection coordinates. Studio previews are staged together as a parts display.

## Rural house and roadside props

Run the generator with `--house` and `--props`. The house export contains 19 components and 19,256 triangles. It has six separate windows, a pivoted front door, detachable roof halves, chimney and gutters. Its interior is a shell. The roadside props export contains nine components and 11,874 triangles. It includes a three-metre wire fence, concrete pole, sagging wire span, streetlamp, two-part dumpster, birch, hedge and grass tuft. These use the same placement and marker convention as the road kit.

## Zefir SM 50 gameplay catalog

Claude's request is in `ServerStorage.CLAUDE_TO_CODEX_READ_ME` in Studio. The separate assembly catalog uses `node assets/vehicles/sm50/source/build.mjs --catalog`. It emits `ZefirSM50Catalog.glb` and a manifest with the exact catalog identifiers, one primitive per part, mount-local geometry, vertex colours, and the final positions of the 25 named frame attachments. It includes 38 installable parts and the frame. The catalog uses the 1.35 m wheelbase and 0.295 m / 0.307 m tire radii specified by Claude. The earlier SM50 GLBs remain the detailed modular art model and its distance variant.

The eight presentation GLBs and two gameplay catalog GLBs were approved by the user. Open Cloud accepted the asset scopes and rejected the tested exports because their directories were absent from Studio's approved upload directories. The GLBs remain on disk and the live Studio previews use transient content.

The stock assembled preview is in `Workspace.ZefirSM50_AssemblyPreview`. Studio verified a 1.35 m distance between the two installed wheel pivots, the fixed tire radii, and agreement with the frame mount markers. The stock preview has 26 MeshParts and 79,440 triangles. The full catalog includes upgrade variants and has 101,072 triangles. The world catalog has nine MeshParts and 16,788 triangles. Both use vertex colors. `install-catalog.luau` is prepared for replacing the staged meshes after upload. Its durable import path still needs a live test.

`--catalog --pbr` builds a separate `ZefirSM50Catalog-pbr.glb`. It retains the same 39 meshes, mounts and triangle counts and adds UVs plus an embedded 1024 px procedural material atlas. The export folder also contains base-color, normal, roughness and metalness PNGs for Roblox SurfaceAppearance setup. The atlas is shared across parts, and its bounded projection prioritizes consistent grain over unique wear placement. The embedded images and accessor counts are checked on export. Roblox texture import and visual validation are pending.

## Dual-motor scooter

Run the generator with `--performance-scooter`. The export contains 44 components, 102 material primitives and 52,562 triangles. It reuses the commuter service layout with a wider deck, dual motors, dual controllers and front and rear disc brakes. The prototype dimensions and spring travel are provisional. The preview is in `Workspace.PerformanceScooter_AssetPreview`.
