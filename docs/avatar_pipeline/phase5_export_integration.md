# Phase 5 – Export & Roblox Integration

## Blender Export Steps
1. Open avatar `.blend` and isolate the mesh + armature.
2. Apply transforms (`Ctrl+A` → Scale/Rotation) on mesh only.
3. Ensure modifiers applied (except Armature) and viewport level matches render level.
4. Use `tools/avatar_pipeline/export_avatar.sh <blend file> <AvatarName>` or manually:
   - `File > Export > FBX`
   - Selected Objects only
   - Apply Transform enabled
   - Forward `-Y`, Up `Z`
   - Add Leaf Bones OFF
   - Smoothing `Face`

## Roblox Studio Import
1. Copy FBX into `Assets/Characters/<Avatar>/FBX/`.
2. In Studio: `Avatar Importer` → `Rigged Accessory/Custom`. Choose R15 rig type.
3. Map mesh parts to BodyPart mesh components (Head, UpperTorso, etc). Use vertex group names to auto-map.
4. Validate animations by playing default walk/run/jump; check for scale drift (should match template arms/legs).
5. Save imported rig as `StarterCharacter` model or store in `ReplicatedStorage/Characters/<Avatar>` for runtime swap.

## Documentation
- Update `Assets/Characters/<Avatar>/README.md` with export date + importer notes.
- Store Roblox Studio screenshot comparisons in `Snapshots/` for QA.

## QA Checklist
- [ ] FBX scale matches R15 template (no micro bones).
- [ ] Vertex colors preserved (if using SurfaceAppearance in Studio, bake textures accordingly).
- [ ] Animations deform properly; no vertex collapse at elbows/knees.
- [ ] Skin tone matches reference under neutral lighting scene (use provided QA place).
