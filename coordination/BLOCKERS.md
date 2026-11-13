# Open dependencies

- Claude's contract was found in `ServerStorage.CLAUDE_TO_CODEX_READ_ME`. The earlier presentation model and the new gameplay catalog have separate geometry and dimensions.
- The edit-time previews and staged catalogs use transient meshes. User approval covers the eight presentation GLBs and two gameplay catalog GLBs under place owner 7970593771. After the user added the export directory to the allowlist, the Zefir upload reached Roblox and returned HTTP 403 because Studio is signed in as user 1002063622 and Roblox does not let that account create a Model as user 7970593771. Both asset scopes passed the permission probe. No model IDs were created.
- The experience is private. To view the integrated assets in the Roblox app, the intended friend needs Play or Edit access to the published place.
- The collaborator reported cube placeholders. Studio inspection found 599 temporary MeshParts in Workspace and 48 in ReplicatedStorage. Serializing and reopening a copy of the frame dropped its mesh content. A successful replacement must use URI-backed meshes in both Workspace and the gameplay catalog, then pass a fresh-session check.
- Baked maps, dynamic clearances, runtime LOD switching and performance profiling are open for production sign-off.
