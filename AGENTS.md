# Streetborn project instructions

- Read the active task board and the matching file under `coordination/` before making changes.
- Codex 1 owns vehicle art, source geometry, exports, and model interfaces. Claude owns gameplay and physics. Codex 2 owns the world.
- SB50 uses metres in asset files and 0.28 m per stud in Roblox. Export with +Y up, −Z forward, and −X to the rider’s left.
- Keep component names, pivots, and attachment names stable when replacing parts. Document any interface change before binding it in gameplay.
- Validate new Studio assets against the live AssetContract and confirm the spawned model in a playtest. Update the manifests when geometry or mounts change.
