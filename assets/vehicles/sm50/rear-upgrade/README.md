# SM50 exhaust, tail and plate

The Blender project contains the editable, fictional **TS 7M42** plate, rebuilt cobalt tail, and stock two-stroke exhaust with heat-stained welds and a brushed silencer. The vehicle meshes are authored in metres at the existing SM50 seat and exhaust datums. Each GLB contains one mesh with embedded materials.

| File | Use |
| --- | --- |
| [SM50-License-Plate.glb](SM50-License-Plate.glb) | Standalone 148 × 122 mm plate with pressed border, reflective face, raised lettering, washers and slotted screws |
| [SM50-Tail.glb](SM50-Tail.glb) | Replacement for `Part_seat_std`. Includes the existing saddle, restyled panels, tapered fender, tail light and mounted TS 7M42 plate |
| [SM50-Exhaust.glb](SM50-Exhaust.glb) | Replacement for `Part_exhaust_std`, with matching UVs and embedded PBR |
| [SM50-Rear-Assets.blend](SM50-Rear-Assets.blend) | Blender source with packed materials |
| [Base color](SM50-Exhaust-BaseColor.png), [normal](SM50-Exhaust-Normal.png), [roughness](SM50-Exhaust-Roughness.png), [metalness](SM50-Exhaust-Metalness.png) | Separate 512 px maps for Roblox SurfaceAppearance on the replacement exhaust mesh |

## Roblox Studio import

1. Import the tail and exhaust in the intended experience with **Upload to Roblox** enabled, using the account or group that owns the place. Keep each export as a single MeshPart. The standalone plate is for reuse elsewhere. The tail already includes it.
2. In Edit mode, stage the uploaded MeshParts under a folder named `SM50RearImports` in Workspace. Name the meshes `Part_seat_std` and `Part_exhaust_std` if the importer changes the names.
3. Run [install-rear.luau](install-rear.luau) in the Studio command bar. It reads the uploaded assets, checks their proportions, preserves the original mounts and fastener attachments, and replaces the two assets under ReplicatedStorage. It uses the +Z-facing raw import convention seen on the original stock SM50. If your import has raw forward along −Z, set `meshFacesPositiveZ = false`.
4. Start a fresh playtest and check the project bike from both sides. The plate faces the rear and the silencer sits on the rider's right. Confirm the tail clears the rear tire through suspension travel, brake lamp illumination lands on the new lens, and the exhaust fasteners align before publishing. Remove the temporary staging folder before saving/publishing. If the importer skips PBR channels, upload the four PNGs and set the replacement exhaust MeshPart's SurfaceAppearance maps.

To regenerate the files, build the base SM50 assets first, then run Blender 4.5 in background mode with `--python build-in-blender.py`. The optional argument after `--` is the path to the base `SM50.glb`.
