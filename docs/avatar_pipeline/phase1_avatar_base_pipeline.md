# Phase 1 – Avatar Base Reconstruction Pipeline

## Inputs
- Storyboard reference images: `Storyboards/concept/intro_screen/pts_intro.png`, `pts_intro_v2.png`, `pts_intro_v3.png`, `pts_intro_v4.png`
- Roblox R15 reference rig FBX (standard avatar) stored under `Assets/RobloxTemplates/R15_Base.fbx`

## Step-by-Step Pipeline (Image → Blender → Roblox)

| Stage | Purpose | Key Actions | Automation/Outputs |
| --- | --- | --- | --- |
| 1. Reference Ingestion | Align reference art with Blender scene scale | Import PNGs as front/side image planes, place inside `Reference` collection, normalize to 5.5–6 Roblox studs height using helper empty (0.28 m per stud). | `scripts/load_reference_planes.py` accepts image path list and outputs `reference_planes.blend` plus JSON manifest containing pixel dimensions. |
| 2. Proportion Extraction | Capture head/body/facial ratios | Use Grease Pencil traces on silhouettes; run `scripts/extract_proportions.py` (uses `bpy` + OpenCV) to map landmark pairs (chin-top, shoulder width, limb lengths). | Generates `Metadata/<AvatarName>_proportions.json` storing ratios + absolute meter targets. |
| 3. Base Mesh Duplication | Prepare Blender template per avatar | Duplicate R15 template mesh and place into `Avatar_<Name>` collection; freeze transforms, enable viewport display of reference overlay. | Automates via Blender operator `avatar_pipeline.create_base_avatar(name, json_path)` that creates vertex color layer `VC_Skin`. |
| 4. Sculpt & Adjust | Match head shape, body proportions, facial planes, skin tone | Sculpt head and torso using symmetry (disable when asymmetry present); use measurement guides (empties) to constrain limb lengths; sample reference colors pipetted from PNG to paint `VC_Skin`. | Save incremental `.blend` per avatar plus `snapshots/<AvatarName>_viewport.png`. |
| 5. Rig Alignment | Bind to Roblox R15 skeleton without altering joint transforms | Import `R15_Base.fbx`, parent mesh with automatic weights, clean up vertex groups to match body parts; run validation script checking bone names, relative lengths, and bounding box height. | Outputs `Metadata/<AvatarName>_rig_report.json` summarizing pass/fail per check. |
| 6. Export → Roblox | Produce FBX + metadata ready for Studio import | Apply transforms, triangulate, export FBX to `Assets/Characters/<AvatarName>/FBX/<AvatarName>_R15.fbx`; create README with import steps; include `.json` descriptor (skin tone hex, scale). | Use Blender preset `Avatar_R15_Export` and CLI `./tools/export_avatar.sh <AvatarName>`. |

## Recommended Tools, Add-ons, Scripts
- **Blender Add-ons**: Image as Planes, Grease Pencil, FaceBuilder (optional for precise facial reconstruction), LoopTools.
- **Custom Scripts** (stored under `tools/avatar_pipeline/`):
  - `load_reference_planes.py`: Creates aligned image planes and empties per character.
  - `extract_proportions.py`: Reads pixel landmarks (annotated via Grease Pencil layers named `L_*`), converts to meters using scene scale.
  - `validate_r15_rig.py`: Ensures vertex groups map 1:1 to Roblox body parts and bone lengths stay within ±2% of standard.
  - `export_avatar.sh`: Calls Blender in headless mode to export selected avatar with preset FBX options.
- **Utility Apps**: PureRef board for side-by-side comparison, Krita/Photoshop for touch-up overlays, ShotGrid/Notion for review tracking.

## Asset Structure & Naming
```
Assets/
  Characters/
    Avatar_<Name>/
      Blend/
        Avatar_<Name>_base.blend
      FBX/
        Avatar_<Name>_R15.fbx
      Metadata/
        Avatar_<Name>_proportions.json
        Avatar_<Name>_rig_report.json
        Avatar_<Name>_skin.json
      Snapshots/
        Avatar_<Name>_viewport.png
```
- Collections in Blender: `Reference`, `Armatures`, `Avatar_<Name>`, `Helpers`.
- Vertex groups strictly follow Roblox naming (`Head`, `UpperTorso`, etc.).
- Skin tone metadata stores hex + sRGB sample coordinates for reproducibility.

## Rigging Approach & Scale Considerations
- Use the untouched Roblox R15 armature; mesh edits adapt to proportions while bone lengths remain canonical to ensure animation compatibility.
- Scene units = meters; insert a `ScaleGuide` empty scaled to 1 stud (0.28 m) and reference heights (5.6 studs default). Scripts enforce bounding-box height = `stud_height * 0.28` ± 2%.
- Weight painting grouped by contiguous regions; facial structure stays on `Head` group. Maintain clean edge loops around elbows/knees to prevent collapse.
- Pose testing uses a set of standard Roblox animations imported as FBX for in-Blender playback before export.

## Potential Challenges & Mitigation
- **Perspective distortion** from concept art: rely on averaged measurements across multiple references and store in JSON to remove subjectivity.
- **Skin tone consistency**: sample from multiple lighting zones, average in linear space, store both raw sample and corrected value; verify in Roblox Studio neutral lighting scene.
- **Topology stretching** during sculpt: Multires workflow with shrinkwrap onto template ensures loops stay aligned; final decimate to maintain <10k tris.
- **Import drift** (scale/placement errors in Roblox Studio): use export preset with `Apply Transform` and `-Y Forward / Z Up`; document Studio import settings so attachments align correctly.
- **Automation reliability**: each script writes logs to `Logs/avatar_pipeline/<AvatarName>_<stage>.log` for traceability.

## Execution Notes for Characters in References
- Process each featured avatar separately (Front-left, Front-right, etc.).
- When references offer varying poses, default to most front-facing shot (v3) for measurements, while v2/v4 provide cross-checks for limb proportion variations.
- Capture facial landmarks (eye width, jaw curve, smile depth) directly from v3 since expressions are clearest; store them in `proportions.json` under `face` namespace for future facial customization layers.
