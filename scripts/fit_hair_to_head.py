"""
BaddieFemale Hair Fitter - Blender Script
==========================================
Automatically fits ANY hair mesh to the BaddieFemale head.

Uses geometry-aware algorithms (raycasting, normal classification) instead
of magic numbers, so it works regardless of hair mesh size or shape.

USAGE:
  1. Export BaddieFemale Head from Roblox Studio as .obj
  2. Download/generate a hair mesh (Meshy AI, Sketchfab, etc.)
  3. Set the 3 file paths in CONFIGURATION below
  4. Run: /Applications/Blender.app/Contents/MacOS/Blender --background --python scripts/fit_hair_to_head.py
"""

import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# ============================================================
# CONFIGURATION
# ============================================================

HEAD_FILE = "/Users/ghost/REPOS/Roblox/my-new-game/assets/BaddieFemale_Head.obj"
HAIR_FILE = "/Users/ghost/REPOS/Roblox/my-new-game/assets/hair/Meshy_AI_Chocolate_Chestnut_Wa_0411011933_texture_fbx/Meshy_AI_Chocolate_Chestnut_Wa_0411011933_texture.fbx"
OUTPUT_FILE = "/Users/ghost/REPOS/Roblox/my-new-game/assets/hair_fitted.fbx"

HEAD_DIMS = Vector((1.146, 1.365, 1.316))

# Rotate head after import (Roblox OBJ exports face backwards)
HEAD_ROTATION_Z_DEG = 180

# Flip hair upside-down if Meshy generated it inverted
HAIR_FLIP_Z = False

# Manual vertical nudge (studs) — positive moves hair up
HAIR_Z_NUDGE = 0.0

# Gap between hair inner surface and skull (prevents z-fighting)
SKIN_OFFSET = 0.02

SAVE_DEBUG_BLEND = True

# ============================================================
# CORE UTILITIES
# ============================================================


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=True)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)


def import_mesh(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    before = set(bpy.data.objects)

    if ext == ".obj":
        if hasattr(bpy.ops.wm, "obj_import"):
            bpy.ops.wm.obj_import(filepath=filepath)
        else:
            bpy.ops.import_scene.obj(filepath=filepath)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=filepath)
    elif ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=filepath)
    else:
        raise ValueError(f"Unsupported format: {ext}")

    after = set(bpy.data.objects)
    new_objs = [o for o in (after - before) if o.type == "MESH"]
    if not new_objs:
        raise RuntimeError(f"No mesh objects found in {filepath}")

    print(f"  Imported {len(new_objs)} mesh object(s):")
    for o in new_objs:
        print(f"    - '{o.name}': {len(o.data.vertices)} verts, {len(o.data.polygons)} faces")

    if len(new_objs) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in new_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = new_objs[0]
        bpy.ops.object.join()
        result = bpy.context.active_object
    else:
        result = new_objs[0]

    bpy.ops.object.select_all(action='DESELECT')
    result.select_set(True)
    bpy.context.view_layer.objects.active = result
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    result.location = (0, 0, 0)
    bpy.context.view_layer.update()

    print(f"  Final mesh: {len(result.data.vertices)} verts, {len(result.data.polygons)} faces")
    return result


def get_bounds(obj):
    coords = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    min_co = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
    max_co = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
    size = max_co - min_co
    center = (min_co + max_co) / 2
    return size, center, min_co, max_co


def select_only(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_transform(obj, location=False, rotation=False, scale=False):
    select_only(obj)
    bpy.ops.object.transform_apply(location=location, rotation=rotation, scale=scale)


# ============================================================
# STEP 1: ORIENT
# ============================================================


def auto_orient_hair(hair_obj):
    size, _, _, _ = get_bounds(hair_obj)
    axes = [("X", size.x), ("Y", size.y), ("Z", size.z)]
    axes.sort(key=lambda a: a[1], reverse=True)
    tallest = axes[0][0]

    select_only(hair_obj)
    if tallest == "X":
        hair_obj.rotation_euler.y += 1.5708
        apply_transform(hair_obj, rotation=True)
        print("  Rotated hair: X->Z (was sideways)")
    elif tallest == "Y":
        hair_obj.rotation_euler.x += 1.5708
        apply_transform(hair_obj, rotation=True)
        print("  Rotated hair: Y->Z (was lying down)")
    else:
        print("  Hair orientation OK (Z is tallest)")


# ============================================================
# STEP 2: SCALE — guarantee hair envelopes head on X and Y
# ============================================================


def scale_hair_to_enclose(hair_obj, head_obj):
    """Scale hair so it fully encloses the head horizontally.
    XY: uniform scale using the LARGER of (head/hair) ratios + 5% buffer.
    Z:  geometric mean of both ratios — keeps height proportional without
        the grotesque stretching that max() caused.
    """
    head_size, _, _, _ = get_bounds(head_obj)
    hair_size, _, _, _ = get_bounds(hair_obj)

    ratio_x = head_size.x / hair_size.x if hair_size.x > 0.001 else 1
    ratio_y = head_size.y / hair_size.y if hair_size.y > 0.001 else 1

    scale_xy = max(ratio_x, ratio_y) * 1.15
    scale_z = math.sqrt(ratio_x * ratio_y)

    hair_obj.scale = (scale_xy, scale_xy, scale_z)
    apply_transform(hair_obj, scale=True)

    new_size, _, _, _ = get_bounds(hair_obj)
    print(f"  Ratios: X={ratio_x:.3f}, Y={ratio_y:.3f}")
    print(f"  Scale applied: XY={scale_xy:.3f}, Z={scale_z:.3f}")
    print(f"  Hair: {hair_size.x:.3f}x{hair_size.y:.3f}x{hair_size.z:.3f}"
          f" -> {new_size.x:.3f}x{new_size.y:.3f}x{new_size.z:.3f}")
    print(f"  Head: {head_size.x:.3f}x{head_size.y:.3f}x{head_size.z:.3f}")


# ============================================================
# STEP 3: POSITION — optimize (Y,Z) for maximum angular coverage
# ============================================================


def build_bvh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    bvh = BVHTree.FromBMesh(bm)
    bm.free()
    return bvh


def fibonacci_sphere(n=500):
    """Generate n uniformly distributed directions on a unit sphere.
    Every direction gets equal weight — no bias from mesh vertex density.
    """
    golden = (1 + math.sqrt(5)) / 2
    directions = []
    for i in range(n):
        theta = math.acos(1 - 2 * (i + 0.5) / n)
        phi = 2 * math.pi * i / golden
        directions.append(Vector((
            math.sin(theta) * math.cos(phi),
            math.sin(theta) * math.sin(phi),
            math.cos(theta),
        )))
    return directions


def detect_face_y(head_obj):
    """Detect which Y direction the face points by vertex density.
    The face has significantly more vertices (eyes, nose, mouth) than
    the smooth back of the skull.
    """
    bm = bmesh.new()
    bm.from_mesh(head_obj.data)
    bm.transform(head_obj.matrix_world)

    _, center, _, _ = get_bounds(head_obj)
    pos_y = sum(1 for v in bm.verts if v.co.y > center.y)
    neg_y = len(bm.verts) - pos_y
    bm.free()

    sign = 1 if pos_y > neg_y else -1
    print(f"  Face detected at {'+ ' if sign == 1 else '-'}Y (vertex split: +Y={pos_y}, -Y={neg_y})")
    return sign


def position_hair_on_head(hair_obj, head_obj):
    """Find the (Y, Z) position that maximizes SCALP coverage.
    Auto-detects the face direction and excludes it from optimization,
    so the optimizer focuses on crown, sides, and back — not the face.
    """
    head_size, head_center, head_min, head_max = get_bounds(head_obj)
    hair_size, hair_center, hair_min, hair_max = get_bounds(hair_obj)

    dx = head_center.x - hair_center.x
    base_dy = head_center.y - hair_center.y

    hair_bvh = build_bvh(hair_obj)

    face_y = detect_face_y(head_obj)

    all_dirs = fibonacci_sphere(600)
    scalp_dirs = [d for d in all_dirs
                  if not (d.y * face_y > 0.15 and d.z < 0.3)
                  and d.z > -0.5]

    head_radius = max(head_size.x, head_size.y, head_size.z) / 2 * 0.95

    print(f"  Using {len(scalp_dirs)} scalp directions (face excluded)")

    def coverage_at(dy, dz):
        center = Vector((head_center.x - dx, head_center.y - dy, head_center.z - dz))
        hits = 0
        for d in scalp_dirs:
            test_point = center + d * head_radius
            loc, _, _, _ = hair_bvh.ray_cast(test_point, d)
            if loc is not None:
                hits += 1
        return hits

    y_search = head_size.y * 0.3
    z_low = head_min.z - hair_center.z - head_size.z * 0.6
    z_high = head_max.z - hair_center.z + head_size.z * 0.6

    print(f"  2D search: Y=[{base_dy - y_search:.3f}, {base_dy + y_search:.3f}]"
          f" Z=[{z_low:.3f}, {z_high:.3f}]")

    y_steps = 15
    z_steps = 25
    best_dy = base_dy
    best_dz = 0
    best_hits = 0

    for yi in range(y_steps + 1):
        dy = base_dy - y_search + 2 * y_search * yi / y_steps
        for zi in range(z_steps + 1):
            dz = z_low + (z_high - z_low) * zi / z_steps
            hits = coverage_at(dy, dz)
            if hits > best_hits:
                best_hits = hits
                best_dy = dy
                best_dz = dz

    y_fine = y_search / y_steps * 1.5
    z_fine = (z_high - z_low) / z_steps * 1.5
    fine_steps = 10
    best_hits = 0

    for yi in range(fine_steps + 1):
        dy = best_dy - y_fine + 2 * y_fine * yi / fine_steps
        for zi in range(fine_steps + 1):
            dz = best_dz - z_fine + 2 * z_fine * zi / fine_steps
            hits = coverage_at(dy, dz)
            if hits > best_hits:
                best_hits = hits
                best_dy = dy
                best_dz = dz

    best_dz += HAIR_Z_NUDGE

    hair_obj.location = Vector((dx, best_dy, best_dz))
    apply_transform(hair_obj, location=True)

    coverage = 100 * best_hits / len(scalp_dirs)
    _, _, new_min, new_max = get_bounds(hair_obj)
    y_shift = best_dy - base_dy
    print(f"  Optimal: Y={best_dy:.3f} ({y_shift:+.3f} from center), Z={best_dz:.3f}")
    print(f"  Scalp coverage: {best_hits}/{len(scalp_dirs)} ({coverage:.1f}%)")
    print(f"  Hair Y: {new_min.y:.3f} to {new_max.y:.3f} | Head Y: {head_min.y:.3f} to {head_max.y:.3f}")
    print(f"  Hair Z: {new_min.z:.3f} to {new_max.z:.3f} | Head Z: {head_min.z:.3f} to {head_max.z:.3f}")


# ============================================================
# STEP 4: SHRINKWRAP — only inner-facing vertices touch skull
# ============================================================


def shrinkwrap_inner_surface(hair_obj, head_obj):
    """Identify inner-surface vertices using face normals: if a vertex's
    normal points toward the head center, it's on the inside of the hair
    (the scalp cavity). Only those vertices get shrinkwrapped to the skull.
    Outer-surface vertices (the visible hairstyle) are never touched.
    """
    select_only(hair_obj)

    _, head_center, _, _ = get_bounds(head_obj)

    bm = bmesh.new()
    bm.from_mesh(hair_obj.data)
    bm.verts.ensure_lookup_table()
    bm.normal_update()

    inner_verts = []
    for v in bm.verts:
        co_world = hair_obj.matrix_world @ v.co
        to_head = (head_center - co_world).normalized()
        normal_world = (hair_obj.matrix_world.to_3x3() @ v.normal).normalized()

        # Dot > 0 means normal faces toward head center (inner surface)
        if normal_world.dot(to_head) > 0.15:
            inner_verts.append(v.index)

    bm.free()

    total = len(hair_obj.data.vertices)
    print(f"  Inner-surface vertices: {len(inner_verts)} / {total} ({100*len(inner_verts)/total:.0f}%)")

    if not inner_verts:
        print("  WARNING: No inner vertices found — skipping shrinkwrap")
        return

    vg = hair_obj.vertex_groups.new(name="InnerSurface")
    for idx in inner_verts:
        vg.add([idx], 1.0, 'REPLACE')

    mod = hair_obj.modifiers.new(name="SkullConform", type='SHRINKWRAP')
    mod.target = head_obj
    mod.wrap_method = 'NEAREST_SURFACEPOINT'
    mod.wrap_mode = 'OUTSIDE_SURFACE'
    mod.offset = SKIN_OFFSET
    mod.vertex_group = "InnerSurface"

    bpy.ops.object.modifier_apply(modifier="SkullConform")
    print(f"  Shrinkwrap applied to inner surface")


# ============================================================
# STEP 5: VERIFY — raycast from head outward to confirm coverage
# ============================================================


def verify_enclosure(hair_obj, head_obj):
    """Cast rays outward from the head surface and check how many hit hair.
    Reports coverage percentage — 100% means no bald patches.
    """
    hair_bvh = build_bvh(hair_obj)

    bm = bmesh.new()
    bm.from_mesh(head_obj.data)
    bm.transform(head_obj.matrix_world)
    bm.normal_update()

    hits = 0
    total = len(bm.verts)

    for v in bm.verts:
        loc, _, _, _ = hair_bvh.ray_cast(v.co, v.normal)
        if loc is not None:
            hits += 1

    bm.free()

    coverage = 100 * hits / total if total > 0 else 0
    print(f"  Head coverage: {hits}/{total} vertices enclosed ({coverage:.1f}%)")

    if coverage < 80:
        print(f"  WARNING: Low coverage — hair may not fully cover the head")
        print(f"  Try: increase scale buffer, adjust HAIR_Z_NUDGE, or check orientation")
    elif coverage < 95:
        print(f"  GOOD: Minor gaps — acceptable for most hairstyles")
    else:
        print(f"  EXCELLENT: Hair fully encloses head")

    return coverage


# ============================================================
# EXPORT
# ============================================================


def set_origin_to_attachment(hair_obj, head_obj):
    _, head_center, _, head_max = get_bounds(head_obj)
    attach_point = Vector((head_center.x, head_center.y, head_max.z))

    select_only(hair_obj)
    bpy.context.scene.cursor.location = attach_point
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    print(f"  Origin at HairAttachment: ({attach_point.x:.3f}, {attach_point.y:.3f}, {attach_point.z:.3f})")


def export_fbx(hair_obj, filepath):
    select_only(hair_obj)
    hair_obj.data.materials.clear()

    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        apply_scale_options='FBX_SCALE_UNITS',
        global_scale=1.0,
        apply_unit_scale=True,
        mesh_smooth_type='FACE',
        use_mesh_modifiers=True,
        bake_space_transform=True,
        object_types={'MESH'},
        axis_forward='-Z',
        axis_up='Y',
    )
    print(f"  Exported: {filepath}")


# ============================================================
# MAIN PIPELINE
# ============================================================


def main():
    print("")
    print("=" * 60)
    print("  BaddieFemale Hair Fitter (v2 — geometry-aware)")
    print("=" * 60)

    if not os.path.exists(HEAD_FILE):
        print(f"\nERROR: Head file not found: {HEAD_FILE}")
        return
    if not os.path.exists(HAIR_FILE):
        print(f"\nERROR: Hair file not found: {HAIR_FILE}")
        return

    out_dir = os.path.dirname(OUTPUT_FILE)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir)

    # 0: Clean
    print("\n[0/7] Clearing scene...")
    clear_scene()

    # 1: Import head
    print("\n[1/7] Importing head...")
    head_obj = import_mesh(HEAD_FILE)
    head_obj.name = "Head_Reference"
    if HEAD_ROTATION_Z_DEG != 0:
        head_obj.rotation_euler.z += math.radians(HEAD_ROTATION_Z_DEG)
        apply_transform(head_obj, rotation=True)
        print(f"  Rotated head {HEAD_ROTATION_Z_DEG}° around Z")
    print(f"  Head bounds: {get_bounds(head_obj)[0]}")

    # 2: Import hair
    print("\n[2/7] Importing hair...")
    hair_obj = import_mesh(HAIR_FILE)
    hair_obj.name = "Hair"
    if HAIR_FLIP_Z:
        hair_obj.rotation_euler.x += math.radians(180)
        apply_transform(hair_obj, rotation=True)
        hair_obj.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        hair_obj.location = (0, 0, 0)
        bpy.context.view_layer.update()
        print("  Flipped hair upside-down")
    print(f"  Hair bounds: {get_bounds(hair_obj)[0]}")

    # 3: Orient + scale
    print("\n[3/7] Orienting and scaling...")
    auto_orient_hair(hair_obj)
    scale_hair_to_enclose(hair_obj, head_obj)

    # 4: Position by maximizing head coverage
    print("\n[4/7] Positioning (coverage optimization)...")
    position_hair_on_head(hair_obj, head_obj)

    # 5: Shrinkwrap inner surface only
    print("\n[5/7] Conforming inner surface to skull...")
    shrinkwrap_inner_surface(hair_obj, head_obj)

    # 6: Verify
    print("\n[6/7] Verifying enclosure...")
    verify_enclosure(hair_obj, head_obj)

    # 7: Export
    print("\n[7/7] Exporting...")
    set_origin_to_attachment(hair_obj, head_obj)
    export_fbx(hair_obj, OUTPUT_FILE)

    if SAVE_DEBUG_BLEND:
        if head_obj and head_obj.name in bpy.data.objects:
            head_obj.display_type = 'WIRE'
            head_obj.show_in_front = True
        blend_path = os.path.splitext(OUTPUT_FILE)[0] + "_debug.blend"
        bpy.ops.wm.save_as_mainfile(filepath=blend_path)
        print(f"  Debug: {blend_path}")

    print("\n" + "=" * 60)
    print("  DONE! Import the FBX into Roblox Studio.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
