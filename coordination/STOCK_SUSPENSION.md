# Stock SM50 suspension in Studio

The stock fork and shock now use 120 mm front travel and 110 mm rear travel. The change applies to both the installed parts and the fallback values in the shared vehicle spec. The units in Luau are metres.

| Studio ModuleScript under ReplicatedStorage.TwoStroke.Parts | Entry | New value |
| --- | --- | --- |
| PartCatalog | `fork_std.stats.travel` | `0.12` |
| PartCatalog | `shock_std.stats.travel` | `0.11` |
| VehicleSpec | `FrontFork` travel fallback | `0.12` |
| VehicleSpec | `RearShock` travel fallback | `0.11` |

The test server built both an empty SM50 spec and an assembly with the stock fork, swingarm, and shock. Both resolved to the new values. The regular test bike spawned, and the normal crosshair mount interaction engaged the rider pose. Both hands stayed within 0.16 studs of their grip targets while seated.

The road test remains open. The client controller reported inactive after the ignition, kickstart, and acceleration input sequence. The short movement observed in the test cannot establish powered riding or bump-stop clearance. The vertical geometry screen is in `assets/vehicles/sm50/exports/ZefirSM50Catalog.validation.json`.
