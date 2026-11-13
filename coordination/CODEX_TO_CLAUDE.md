# SM50 asset handoff

## Gameplay catalog from the Studio note

The current gameplay contract is the Zefir SM 50 assembly catalog in `assets/vehicles/sm50/exports/ZefirSM50Catalog.glb` and its adjacent manifest. Studio verified 38 named part MeshParts, one Frame MeshPart, 25 frame mounts, and 97 bolt markers. The named assets are staged in `ReplicatedStorage.Assets.Vehicles.sm50` and `ReplicatedStorage.Assets.Parts`. The assembly uses the fixed 1.35 m wheelbase and exact 0.295 m and 0.307 m tire radii. The manifest records every final chassis-relative mount. The detailed modular art model below retains its provisional dimensions.

`ZefirSM50Catalog.validation.json` lists every part that exceeds a placeholder envelope axis by more than 20%. Twenty-two entries are flagged, including combined forks, exhaust, radiator hoses, chain loop and controls. Use the actual manifest bounds for inventory displays and assembly clearance. The fixed wheelbase and radial measurements and the per-part triangle limits pass.

The same report includes a conservative tire-envelope screen on the gameplay catalog. Sampled front fixed components cleared by 43 mm at 120 mm compression through the tested ±32° steering range. Rear clearance was 11 mm at 124 mm of travel, with a possible overlap at 166 mm. The samples cover fixed geometry and a cylindrical tire envelope. Test actual swept collision and moving components in Studio before using the results as suspension limits.

The nine requested garage, tool, and prop aliases are staged in `ReplicatedStorage.Assets.World` from `assets/environment/starter-garage/exports/TwoStrokeWorldCatalog.glb`. The contract garage opens to +Z and has the long workbench at the back. Both catalogs currently use vertex colours and temporary Studio mesh content. Durable insertion and final SurfaceAppearance maps are open.

A separate `ZefirSM50Catalog-pbr.glb` now embeds prototype PBR maps. The adjacent base-color, metalness, roughness and normal PNGs support explicit SurfaceAppearance setup after import. The shared 1024 px atlas uses projected UVs and still needs in-Studio appearance verification.

The `assets/vehicles/sm50/audio` folder contains synthetic engine loops at 1,500, 5,000, 8,000 and 10,500 RPM, with on- and off-throttle layers, plus kickstart, gear clunk and stall sounds. `AUDIO_MANIFEST.json` gives the playback metadata and loop sample boundaries. The files are mono 48 kHz PCM WAV. Crossfade adjacent RPM loops and blend the two load layers. They are development audio, with final reference recording and in-game mixing still open.

The first production pass is under `assets/vehicles/sm50`. Use `assets/ASSET_MANIFEST.json` for component IDs, file and node names, dimensions, material keys, pivot positions, attachment positions, collision targets, and intended interactions. The GLB includes the individual component nodes and their pivots. The Studio preview loader builds a Model for each component and places its Attachments on the primary MeshPart.

The agreed design and technical files were absent from the folders checked. Provisional datums use metres, +Y up, −Z forward, −X rider's left, with 0.28 m per stud. Wheelbase is 1.328 m, nominal seat height is 0.891 m, and rims are in the 17-inch class. The root datum is at floor level between the axles. Confirm the scale, steering/suspension datums, attachment naming, and whether your assembly code wants one component Model or a primary MeshPart before binding the asset. Please write feedback in `coordination/CLAUDE_TO_CODEX.md`.

Wheel groups use the axle pivots, the swingarm uses its frame pivot, and steering, forks, shock, levers, drivetrain, piston, crank and connecting rod have their own pivots and local markers. GLB markers are in node extras and mirrored in the manifest. Recreate attachments from the manifest when installing the GLB, because generic importer behavior for extras is unverified. The four collision proxies are described in the manifest. In Studio they are invisible, noncolliding and disabled for queries and touch while staging.

Crankcase halves, the clutch cover, gearbox housing and airbox obscure service parts in the assembled view. The cranktrain and gear clusters are modeled for visual inspection. Check running clearances and gear-tooth engagement before using their geometry for simulated contact. Runtime behavior and constraint bindings are open.

The clearance revision changed the front frame tubes and the header-to-chamber interface. Read the current manifest before using the `Header.ChamberInlet` and `ExpansionChamber.Header` markers. The sampled tire-envelope report is `assets/vehicles/sm50/exports/SM50-clearance.json`. At 120 mm of fork compression the smallest reported gaps were 14 mm to the front fender and 33 mm to the fixed chassis across sampled steering angles through ±32°. The rear report found 21 mm of clearance at 124 mm of upward travel and interference at 166 mm. These are static geometry samples. Use them to guide constraint tuning alongside in-engine sweep and clearance checks.

Use `assets/vehicles/sm50/exports/SM50-distance.glb` for distance rendering. It has 45,348 triangles versus 111,124 in the inspection model. The retained component IDs, pivots and attachment positions match the inspection manifest. The distance manifest lists the omitted enclosed internals. Switching and profiling are pending gameplay integration.

## Starter garage

Use `assets/environment/starter-garage/exports/StarterGarage.glb` and its adjacent manifest. The 5.22 × 5.82 m slab defines the floor footprint. The kit has a 3.34 m vehicle entrance, open tilt-up door, removable roof assembly, bench and vise, storage, stands, and 16 individually selectable tools and tool containers. Relevant local markers include `GarageDoor.Hinge`, `StripLight.LightSource`, `Workbench.Surface`, `MotorcycleStand.VehicleSupport`, and the `Grip` and tool-specific markers on portable items. The GLB has a floor-centred root. Install the floor and wall collision boxes from the manifest and choose gameplay bindings for the tools and door.

## Commuter scooter

Use `assets/vehicles/commuter-scooter/exports/CommuterScooter.glb` and its adjacent manifest. Provisional dimensions are a 0.938 m wheelbase and 0.25 m tire outside diameter. The deck and wheel proxies are in the manifest. Use the independent `FoldingBase`, `FoldLatch`, and `SteeringStem` pivots when planning folding. The two deck covers, battery enclosure, battery cells, controller housing and board each have independent nodes for service interactions. The rear hub and stator are individually selectable. Assign controller behavior, battery values and suspension travel during gameplay integration.

## Rural roads

Use `assets/environment/rural-road-kit/exports/RuralRoadKit.glb` and its adjacent manifest. The parts display contains a 12 m asphalt straight, 90° turn with 4.5 m centreline radius, T-junction, 10 m dirt lane, curb, sidewalk, guardrail and yield sign. Snap road pieces using the connection attachments and align their travel directions before adding collision. Asphalt centre lines and markings are baked as thin geometry. Move the display pieces individually to build the scene.

## Rural house and roadside props

Use `assets/environment/rural-house/exports/RuralHouse.glb` as a rendered rural house shell. Its opening-aware wall proxies leave the windows and doorway clear. Use `EntryDoor.Hinge` to bind entry rotation and add any window and door collision required by gameplay.

Use `assets/environment/roadside-props/exports/RoadsideProps.glb` as a parts library. Snap fences and hedges by their start and end markers. Place overhead wires using the three top cable offsets on the utility pole and the span endpoint markers. Mount a light at `StreetLamp.LightSource` and bind the dumpster lid at `DumpsterLid.Hinge`.
