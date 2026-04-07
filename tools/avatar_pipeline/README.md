# Avatar Pipeline Tools

## `load_reference_planes.py`
Loads storyboard PNGs as Blender image planes with consistent stud-based scaling.

## `extract_proportions.py`
Parses Grease Pencil landmarks and outputs measurement JSON for each avatar.

## `validate_r15_rig.py`
Checks vertex groups + bone lengths for R15 compatibility.

## `apply_proportions.py`
Duplicates the base R15 mesh and scales it to match metadata.

Usage example:
```
blender master.blend --python tools/avatar_pipeline/apply_proportions.py -- \
    --source-mesh R15_Base --avatars Blonde BrunetteBlack LeaderPink LilacBucket
```

The script reads each avatar's `Metadata/<Avatar>_proportions.json` and `..._skin.json`, scales the mesh height/shoulder/hip widths, and fills the `VC_Skin` vertex color layer with the sampled tone.

## `export_avatar.sh`
Wrapper around Blender's FBX exporter to produce R15-ready FBX files per avatar.
