# Roblox mesh repair

The cube placeholders reproduce when Studio saves temporary EditableMesh geometry. Before the repair, the connected edit session contained 599 Workspace MeshParts and 48 catalog MeshParts backed by temporary content. A serialized copy of the frame reopened with empty mesh content.

## Current verification

The connected Two-Stroke edit session has 163 URI-backed Workspace meshes and 48 URI-backed catalog meshes. A fresh Studio client checked 233 meshes and reported 260 successful asset fetches with zero failures. This covers the current map, stock bikes and scooter display. The Senda catalog still needs its own import. The intended friend's published-game session is pending verification.

## Approved uploads

The destination is the owner account 7970593771 for the private place 112877997436632. User approval covers the files below. The Zefir request passed the directory gate and reached Roblox. Roblox returned HTTP 403 because the connected Studio is signed in as 1002063622, which cannot create an asset as 7970593771. Reconnect Studio as the place owner, with the export directories and asset scopes enabled in that session.

| GLB | Folder under assets |
| --- | --- |
| SM50.glb | vehicles/sm50/exports |
| SM50-distance.glb | vehicles/sm50/exports |
| ZefirSM50Catalog.glb | vehicles/sm50/exports |
| CommuterScooter.glb | vehicles/commuter-scooter/exports |
| PerformanceScooter.glb | vehicles/performance-scooter/exports |
| StarterGarage.glb | environment/starter-garage/exports |
| TwoStrokeWorldCatalog.glb | environment/starter-garage/exports |
| RuralRoadKit.glb | environment/rural-road-kit/exports |
| RuralHouse.glb | environment/rural-house/exports |
| RoadsideProps.glb | environment/roadside-props/exports |

## Replace and verify

Run `node assets/vehicles/sm50/source/mesh-upload-plan.mjs` to check the ten approved files, resolve their exact paths and record their SHA-256 hashes before submitting uploads.

1. Upload the Zefir assembly catalog first. Record the operation ID before polling it. When approved, insert the asset in an isolated staging folder and inspect the hierarchy and its mesh references.
2. Run `install-catalog.luau` with the imported Model and its decoded manifest. It checks every component and restores the checked part names, size, pivots and attachments from the catalog. Repeat for the world catalog.
3. Build the display asset mapping with `resolve-preview-mesh.luau`. Pass a table keyed by each preview root's `AssetId`, with a `model` and decoded `manifest` for each value. The resolver uses explicit names or unique per-material mesh bounds. If several meshes have matching bounds, confirm their material correspondence in the importer before assigning MaterialKey attributes.
4. Use `repair-preview-meshes.luau` with the intended display roots and the resolver. It checks all replacements before applying them and preserves the existing placement. Check the assembled motorcycle and engine service display alongside the environment assets.
5. Run `check-studio-meshes.luau` in Studio Edit to scan all Workspace and catalog meshes and serialize a representative mesh from each root. Review front, side and interior views. Save the place, start a fresh Studio Play session and run the same script in the Client data model to check asset fetches. Inspect `passed`, `roundTripFailures` and `fetchFailures`. Confirm the intended friend can view the published place using the existing private access settings.

The missing-source branch was checked on the 26-part assembled Zefir and made zero changes. The bounds matcher identified both material meshes on a duplicate scooter wheel after their names and material attributes were changed. All ten approved GLBs and manifests rebuilt with valid per-material bounds.
