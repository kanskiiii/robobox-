# Codex 1 to Claude

## SB50 starter vehicle

The runtime path is `ServerStorage.Assets.Vehicles.SB50`. The vehicle is a 1.380 m wheelbase two-stroke supermoto with a nominal 0.891 m seat height, 17 in rims, and 0.296 m front and 0.307 m rear tire radii. It uses the live AssetContract v1 and includes both suspension attachments, both wheel welds, SteeringWeld, VehicleSeat, and the dashboard SurfaceGui. The invisible Chassis carries all vehicle collision and mass. The full inspection model includes the enclosed service parts.

`FrontWheel` and `RearWheel` rotate about local +X. The steering root uses a 25° rake and rotates about local Y. The front brake disc rotates with the wheel and the caliper follows the steering. The rear caliper, swingarm, shock, and chain are independently selectable in Body. The current runtime remains driven by the existing three welds. Independent fork compression, swingarm articulation, chain animation, lever animation, and service interactions still need gameplay binding.

The model origin is the chassis COM at 0.72 m above the nominal tire contact plane. Component `pivotM` values in the [game manifest](../assets/manifests/SB50-game.json) are measured from the art model’s floor-centred origin. Subtract `[0, 0.72, 0]` and divide by 0.28 to obtain chassis-relative studs. `attachmentLocalM` is relative to each component pivot. The seat group in Studio is named `SeatPad` and has asset ID `sb50.Seat`. The root `Seat` is the VehicleSeat.

See the [component manifest](../assets/manifests/SB50-components.json) for pivot-local replacement exports and interface IDs. The alternate seat and silencer finishes use the same geometry and bolt positions as stock. Use the exact stock pivot and attachment transforms for replacements.

The current game mesh is 46,460 triangles against the contract’s advisory 40,000-triangle target. Use the game export for in-game profiling before deciding where to simplify further. The teardown mesh is 113,612 triangles. It is intended for close-up inspection. The Blender and inspection GLB carry PBR textures. The installed Studio model uses native materials.

The original inbound files named in the brief were unavailable here. The live `ServerStorage.Coordination.README_FOR_CODEX` and `ReplicatedStorage.Shared.Vehicle.AssetContract` provided the integration requirements.

Studio playtest spawned the asset in `Workspace.Vehicles.SB50` on both server and client, with all 159 embedded meshes and a measured 1.380 m axle separation. Saved to Roblox as place version 6.
