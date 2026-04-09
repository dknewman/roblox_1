# Phase 5 – Roblox Studio Import / QA Notes

Roblox Studio launch command (executed locally):
```
open -a RobloxStudio
```

## Successful Import: BaddieFemale (2026-04-09)

### Source
- Blender file: `blender_baddie.blend` (Blender 5.1.0)
- FBX export: `/Users/ghost/BLENDER_EXPORT/blender_baddie.fbx`
- Mesh stats: 5,002 vertices, 15,000 edges, 10,000 faces, 10,000 triangles
- Export settings: Mesh only, embedded textures, FBX All scalings, scale 0.01, -Z Forward, Y Up

### Import Process
1. Opened `build.rbxlx` in Roblox Studio
2. Used **Avatar tab → Setup → Import 3D** (not the regular 3D importer)
3. Avatar Auto-Setup successfully generated R15 rig
4. Model placed in **ServerStorage** as `BaddieFemale`

### Mesh Cleanup Performed
- Merge by Distance (removed duplicate vertices)
- Recalculate Normals (fixed face orientation)
- Delete Loose (removed stray geometry)
- Non-Manifold check: **0 non-manifold edges** (mesh is watertight)
- Armature + Armature modifier removed (Auto-Setup needs bare mesh)

### Validation Warnings (9 total, non-blocking)
| Warning | Detail |
|---------|--------|
| Frown expression | Cannot detect for Dynamic Head |
| Right eye close | Cannot detect for Dynamic Head |
| Left eye close | Cannot detect for Dynamic Head |
| Torso poly count | 2,840 tris (max 1,750 for Marketplace) |
| LeftLeg poly count | 2,048 tris (max 1,248 for Marketplace) |
| RightLeg poly count | 1,908 tris (max 1,248 for Marketplace) |
| LeftGripAttachment | Orientation deviates from expected |
| RightGripAttachment | Orientation deviates from expected |

### Result
- Full R15 rig: 15 body parts + HumanoidRootPart + Humanoid + AnimateScript
- Used for both NPCs (NPCSpawner clones from ServerStorage) and player character (CharacterCreator clones for female players)
- Tested in-game: NPCs spawn and wander, player character spawns correctly

## Previously Prepared Avatars (Pending Import)
- Blonde
- BrunetteBlack
- LeaderPink
- LilacBucket

### Optional Plugin Automation
- A Studio plugin (`tools/studio_plugin/BaddieBatchImporter.lua`) automates the import:
  1. Copy the Lua file into `~/Library/Application Support/Roblox/Plugins/`.
  2. Enable the **Avatar Importer API** beta feature in Studio.
  3. In Studio, click the new toolbar button `Baddies Tools → Batch Import` to ingest all FBX files and parent them to `ReplicatedStorage/Characters`.
