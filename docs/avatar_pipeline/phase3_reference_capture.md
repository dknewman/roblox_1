# Phase 3 – Reference Capture Execution

Source image: `pts_intro_v3.png` (primary). Pixel measurements extracted via custom PNG parser (`python` script in repo history) using bounding boxes:
- Blonde (left): x 150–330
- BrunetteBlack (mid-left): x 320–470
- LeaderPink (center): x 470–640
- LilacBucket (right): x 640–820

Each bounding box was normalized to 5.6 studs of height to match stylized R15 scale. Shoulder/hip widths sampled at 25% and 55% of figure height respectively. Skin tones sampled from 17×17 px patches centered on facial coordinates.

Outputs are stored under `Assets/Characters/<Avatar>/Metadata/` and include:
- `<Avatar>_proportions.json`: bounding box info, stud height, derived widths.
- `<Avatar>_skin.json`: averaged RGB + hex for face tone.

See `references/skin_palette.json` for consolidated tones.
