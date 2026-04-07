# Phase 2 – Tooling & Data Prep Report

Artifacts produced:
- `tools/avatar_pipeline/load_reference_planes.py`: Blender helper to spawn normalized reference planes.
- `tools/avatar_pipeline/extract_proportions.py`: exports Grease Pencil landmark measurements to JSON.
- `tools/avatar_pipeline/validate_r15_rig.py`: checks mesh + armature conformity to R15 standards.
- `tools/avatar_pipeline/export_avatar.sh`: bash wrapper around Blender FBX export workflow.
- `scripts/avatar_pipeline_cli.py`: lightweight CLI to inspect the reference manifest.
- `references/reference_manifest.json`: auto-generated metadata for all storyboard PNGs.
- `references/baddies_board.prf`: placeholder PureRef board for remote teams to replace with final board.

Next actions: finalize PureRef board, drop `R15_Base.fbx`, then move into reference capture (Phase 3).
