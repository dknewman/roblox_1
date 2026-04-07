# Avatar Brief – Blonde Influencer (front-left)

## Reference Summary
- Primary source: `pts_intro_v3.png` (x 150–330, y 140–900).
- Height target: 5.6 studs (≈1.568 m).
- Skin: `#b168af` (from cheeks; adjust to slightly warmer tone in neutral lighting).

## Sculpt Notes
1. **Head Shape**: Wide chin taper, pronounced cheekbones; keep jaw corners soft. Set head height ≈1 stud using proportion file. Eyes slightly angled upward to keep winking pose possible later.
2. **Body Proportions**:
   - Shoulders ~1.24 studs; hips ~1.08 studs.
   - Torso reads shorter due to crop top; keep waist height just below 50% of total height.
   - Arms slightly outward for selfie pose; keep lengths canonical to R15.
3. **Facial Structure**: Wide-set eyes, high cheekbone plane, smiling mouth offset to left to support winking expression; eyelids thicker on top to support liner look.
4. **Skin Tone Workflow**: Paint vertex color layer `VC_Skin` with gradient: cheeks lighten to RGB (219,140,206), forehead/back to base (#b168af), underside slightly darker for shading.

## Rigging Hooks
- Keep default R15 head pivot for animated wink; jaw area should deform minimally.
- Weight paint `UpperTorso` to maintain shrug silhouette; ensure `RightUpperArm` weighting allows phone-holding pose without collapsing shoulder.

## Checklist
- [ ] Sculpt head/torso per notes
- [ ] Validate with `validate_r15_rig.py` once weights applied
- [ ] Export viewport snapshot for approval
