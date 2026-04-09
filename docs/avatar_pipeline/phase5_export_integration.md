# Phase 5 – Export & Roblox Integration

## Blender Export Steps (Verified 2026-04-09)

### Mesh Preparation
1. Open avatar `.blend` file in Blender.
2. Enter Edit Mode, select all, run mesh cleanup:
   - `Mesh > Merge > By Distance` (remove duplicate vertices)
   - `Mesh > Normals > Recalculate Outside` (fix normals)
   - `Mesh > Clean Up > Delete Loose` (remove stray geometry)
   - `Select > All by Trait > Non Manifold` (verify no holes — 0 selected = clean)
3. **Remove the Armature**: Delete the Armature object and remove the Armature modifier from the mesh. Avatar Auto-Setup needs a bare mesh to generate its own R15 rig.
4. Apply transforms: `Ctrl+A` → All Transforms.
5. Scale to Roblox size: Set Scale X/Y/Z to `0.01` in Properties, then `Ctrl+A` → All Transforms.

### FBX Export Settings
- `File > Export > FBX`
- **Object Types**: Mesh only (uncheck Armature, Empty, Camera, Lamp)
- **Path Mode**: Copy + click box icon (embed textures)
- **Apply Scalings**: FBX All
- **Forward**: -Z Forward
- **Up**: Y Up
- Export to `/Users/ghost/BLENDER_EXPORT/blender_baddie.fbx`

## Roblox Studio Import (Avatar Auto-Setup)
1. In Studio: **Avatar tab → Setup** (not the regular 3D importer)
2. Click **Import 3D** and select the FBX file
3. In Import Preview:
   - Verify File Dimensions are character-sized (~5 studs tall)
   - Fix texture paths if broken (Color File Path)
   - Click **Import**
4. Avatar Auto-Setup generates a full R15 rig:
   - 15 body parts (Head, UpperTorso, LowerTorso, LeftUpperArm, LeftLowerArm, LeftHand, RightUpperArm, RightLowerArm, RightHand, LeftUpperLeg, LeftLowerLeg, LeftFoot, RightUpperLeg, RightLowerLeg, RightFoot)
   - HumanoidRootPart, Humanoid, AnimateScript, Body Colors, InitialPoses
5. Review validation warnings (OK to dismiss for in-game use; only blocks Marketplace upload)
6. Move the auto-setup model to **ServerStorage** and rename (e.g., `BaddieFemale`)

## Code Integration
- NPCSpawner clones the model from ServerStorage for each NPC
- CharacterCreator clones the model and assigns as `player.Character` for female players
- Both reference the model by name via `Constants.Outfits.Female.DTIRig`

## Known Validation Warnings (Non-Blocking)
- Dynamic Head facial expressions not detected (frown, eye close)
- Torso poly count exceeds Marketplace limit (2840 > 1750)
- Leg poly count exceeds Marketplace limit (LeftLeg 2048, RightLeg 1908 > 1248)
- Grip attachment orientation slightly off on both hands

## QA Checklist
- [x] FBX scale matches R15 template (~5 studs tall).
- [x] Mesh is manifold (no holes, no non-manifold edges).
- [x] Avatar Auto-Setup generates complete R15 rig.
- [x] NPCs spawn and wander correctly with custom model.
- [x] Player character uses custom model via CharacterCreator.
- [ ] Animations deform properly; check elbows/knees under movement.
- [ ] Skin tone matches reference under plaza neon lighting.
