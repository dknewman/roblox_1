# Phase 5 – Roblox Studio Import / QA Notes

Roblox Studio launch command (executed locally):
```
open -a RobloxStudio
```

## Import Checklist Per Avatar
1. Open the QA test place (e.g., `build.rbxlx`) in Roblox Studio.
2. `Avatar Importer` → `Custom` (R15).
3. Import FBX from `Assets/Characters/<Avatar>/FBX/<Avatar>_R15.fbx`.
4. When prompted, map mesh to BodyParts using vertex group names.
5. After import:
   - Verify total height via the built-in measurement tool (should match template ~5.6 studs).
   - Play default animations (walk/run/jump) to validate deformations.
   - Capture viewport screenshots for front and three-quarter views.
6. Save the rig as `ReplicatedStorage/Characters/<Avatar>` for later selection.

## Status
- Assets prepared (FBX + metadata) for these avatars:
  - Blonde
  - BrunetteBlack
  - LeaderPink
  - LilacBucket

### Optional Plugin Automation
- A Studio plugin (`tools/studio_plugin/BaddieBatchImporter.lua`) automates the import:
  1. Copy the Lua file into `~/Library/Application Support/Roblox/Plugins/`.
  2. Enable the **Avatar Importer API** beta feature in Studio.
  3. In Studio, click the new toolbar button `Baddies Tools → Batch Import` to ingest all FBX files and parent them to `ReplicatedStorage/Characters`.

- Awaiting in-Studio verification and screenshot capture (requires GUI interaction, but the plugin handles the import loops).
