# Phase 4 – Base Avatar Sculpt + Rig Prep

## Scene Setup
1. Open Blender master scene; set units to meters.
2. Import `Assets/RobloxTemplates/R15_Base.fbx` and place in `Armatures` collection.
3. Duplicate the template mesh for each avatar, rename object/mesh data to `<AvatarName>` (automate via `apply_proportions.py`).
4. Link reference planes (Phase 2) and proportion JSONs to the scene (custom operator `avatar_pipeline.create_base_avatar`).

## Sculpt Workflow
- Enable Multires modifier with 2 levels for face refinement; keep base topology identical to R15 mesh.
- Use measurement empties (heads, shoulders) referencing `Metadata/<Avatar>_proportions.json` to guide scaling.
- Optionally run `tools/avatar_pipeline/apply_proportions.py --source-mesh R15_Base --avatars ...` to generate pre-scaled duplicates before sculpting facial details.
- Sculpt order: head silhouette → torso width → limb adjustments → facial features.
- Maintain limb length to match R15 bones (do not scale bones).
- Paint vertex color layer `VC_Skin` using sampled tones from `<Avatar>_skin.json`.
- Save each result as `Assets/Characters/<Avatar>/Blend/<Avatar>_base.blend`.

## Rig Binding
1. Parent mesh to R15 armature with `With Automatic Weights`.
2. Clean vertex groups to ensure one-to-one mapping with expected R15 groups.
3. Run `tools/avatar_pipeline/validate_r15_rig.py --mesh <AvatarName> --armature R15 --output Assets/Characters/<Avatar>/Metadata/<Avatar>_rig_report.json`.
4. Load walk + idle animations for deformation checks; adjust weights where necessary (elbows, knees, shoulders).

## Deliverables
- Updated `.blend` files containing sculpt + armature linkage.
- Validation JSON containing bone presence, bounding box height, vertex group status.
- Viewport renders: `Assets/Characters/<Avatar>/Snapshots/<Avatar>_viewport.png` (front and 3/4 views).
