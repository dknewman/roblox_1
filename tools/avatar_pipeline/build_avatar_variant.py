#!/usr/bin/env python3
"""Builds a stylized avatar variant from the procedural R15 base."""
from __future__ import annotations

import argparse
import json
import math
import sys
from copy import deepcopy
from pathlib import Path

import bpy
from mathutils import Vector

CURRENT_DIR = Path(bpy.path.abspath('//')).resolve()
REPO_ROOT = CURRENT_DIR.parent.parent
sys.path.append(str(REPO_ROOT))

from tools.avatar_pipeline import apply_proportions as ap  # type: ignore
from tools.avatar_pipeline import validate_r15_rig as validator  # type: ignore

META_ROOT = REPO_ROOT / 'Assets/Characters'

DEFAULT_STYLE = {
    'head': {
        'upper_width': 1.0,
        'jaw_width': 1.0,
        'depth_upper': 1.0,
        'depth_lower': 1.0,
        'height_scale': 1.0,
        'chin_offset': 0.0,
    },
    'torso': {
        'upper_scale': 1.0,
        'lower_scale': 1.0,
    },
    'limbs': {
        'arm_scale': 1.0,
        'leg_scale': 1.0,
    },
}

STYLE_PRESETS = {
    'Blonde': {
        'head': {'upper_width': 1.08, 'jaw_width': 1.12, 'depth_upper': 0.95, 'depth_lower': 0.9, 'height_scale': 0.97, 'chin_offset': 0.015},
        'torso': {'upper_scale': 1.0, 'lower_scale': 0.94},
    },
    'BrunetteBlack': {
        'head': {'upper_width': 0.98, 'jaw_width': 0.9, 'depth_upper': 0.98, 'depth_lower': 0.92, 'height_scale': 1.02, 'chin_offset': -0.01},
        'torso': {'upper_scale': 1.04, 'lower_scale': 1.02},
    },
    'LeaderPink': {
        'head': {'upper_width': 1.02, 'jaw_width': 1.0, 'depth_upper': 1.0, 'depth_lower': 0.96, 'height_scale': 1.05, 'chin_offset': 0.0},
        'torso': {'upper_scale': 1.05, 'lower_scale': 1.0},
    },
    'LilacBucket': {
        'head': {'upper_width': 1.12, 'jaw_width': 1.1, 'depth_upper': 0.96, 'depth_lower': 0.92, 'height_scale': 0.95, 'chin_offset': 0.02},
        'torso': {'upper_scale': 0.98, 'lower_scale': 0.92},
        'limbs': {'leg_scale': 0.96},
    },
}

SNAPSHOT_RES = 1024


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def load_metadata(avatar: str) -> dict:
    path = META_ROOT / avatar / 'Metadata' / f'{avatar}_proportions.json'
    if not path.exists():
        raise RuntimeError(f'Metadata missing for {avatar}: {path}')
    data = json.loads(path.read_text())
    return data


def prepare_style(avatar: str) -> dict:
    style = deepcopy(DEFAULT_STYLE)
    preset = STYLE_PRESETS.get(avatar)
    if preset:
        for key, values in preset.items():
            style[key].update(values)
    return style


def duplicate_base(avatar: str):
    ap.process_avatar('R15_Base', avatar, META_ROOT)
    base_obj = bpy.data.objects.get('R15_Base')
    avatar_obj = bpy.data.objects.get(avatar)
    if base_obj:
        bpy.data.objects.remove(base_obj, do_unlink=True)
    armature = bpy.data.objects.get('R15_Armature')
    if armature:
        armature.name = f'{avatar}_Armature'
    else:
        raise RuntimeError('Base armature not found')
    return avatar_obj, armature


def recenter_mesh_and_armature(mesh_obj, armature):
    bounds = compute_bounds(mesh_obj)
    offset = Vector((
        -bounds['center'].x,
        -bounds['center'].y,
        -bounds['min'].z,
    ))
    mesh_obj.location += offset
    if armature is not None:
        armature.location += offset
    return compute_bounds(mesh_obj)


def apply_head_style(mesh_obj, params):
    indices = ap._vertex_indices_for_group(mesh_obj, 'Head', weight_threshold=0.0)
    if not indices:
        return
    verts = mesh_obj.data.vertices
    xs = [verts[i].co.x for i in indices]
    ys = [verts[i].co.y for i in indices]
    zs = [verts[i].co.z for i in indices]
    center_x = sum(xs) / len(xs)
    center_y = sum(ys) / len(ys)
    min_z, max_z = min(zs), max(zs)
    height = max_z - min_z
    if height == 0:
        height = 1.0
    for vid in indices:
        vert = verts[vid]
        t = (vert.co.z - min_z) / height
        width_scale = lerp(params['jaw_width'], params['upper_width'], t)
        depth_scale = lerp(params['depth_lower'], params['depth_upper'], t)
        vert.co.x = center_x + (vert.co.x - center_x) * width_scale
        vert.co.y = center_y + (vert.co.y - center_y) * depth_scale
        vert.co.z = min_z + (vert.co.z - min_z) * params['height_scale'] - params['chin_offset'] * (1 - t)


def scale_group_z(mesh_obj, group_name: str, scale: float):
    if abs(scale - 1.0) < 1e-4:
        return
    indices = ap._vertex_indices_for_group(mesh_obj, group_name, weight_threshold=0.0)
    if not indices:
        return
    verts = mesh_obj.data.vertices
    pivot = sum(verts[i].co.z for i in indices) / len(indices)
    for vid in indices:
        vert = verts[vid]
        vert.co.z = pivot + (vert.co.z - pivot) * scale


def apply_torso_style(mesh_obj, params):
    scale_group_z(mesh_obj, 'UpperTorso', params.get('upper_scale', 1.0))
    scale_group_z(mesh_obj, 'LowerTorso', params.get('lower_scale', 1.0))


def apply_limb_style(mesh_obj, params):
    arm_scale = params.get('arm_scale', 1.0)
    leg_scale = params.get('leg_scale', 1.0)
    for group in ('LeftUpperArm', 'LeftLowerArm', 'LeftHand', 'RightUpperArm', 'RightLowerArm', 'RightHand'):
        scale_group_z(mesh_obj, group, arm_scale)
    for group in ('LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot', 'RightUpperLeg', 'RightLowerLeg', 'RightFoot'):
        scale_group_z(mesh_obj, group, leg_scale)


def ensure_skin_material(mesh_obj, avatar: str):
    mat_name = f'Skin_{avatar}'
    mat = bpy.data.materials.get(mat_name)
    if mat is None:
        mat = bpy.data.materials.new(mat_name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get('Principled BSDF')
        if bsdf is None:
            bsdf = nodes.new('ShaderNodeBsdfPrincipled')
        vc = nodes.new('ShaderNodeVertexColor')
        vc.layer_name = 'VC_Skin'
        links.new(bsdf.inputs['Base Color'], vc.outputs['Color'])
        material_output = nodes.get('Material Output')
        if material_output is None:
            material_output = nodes.new('ShaderNodeOutputMaterial')
        links.new(material_output.inputs['Surface'], bsdf.outputs['BSDF'])
    if mesh_obj.data.materials:
        mesh_obj.data.materials[0] = mat
    else:
        mesh_obj.data.materials.append(mat)


def setup_environment():
    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = SNAPSHOT_RES
    bpy.context.scene.render.resolution_y = SNAPSHOT_RES
    bpy.context.scene.render.film_transparent = False
    bpy.context.scene.world.color = (0.95, 0.82, 0.92)
    bpy.context.scene.render.image_settings.file_format = 'PNG'

    cam_data = bpy.data.cameras.new('AvatarCamera')
    cam_obj = bpy.data.objects.new('AvatarCamera', cam_data)
    cam_data.lens = 60
    bpy.context.collection.objects.link(cam_obj)

    key_light = bpy.data.lights.new('KeyLight', type='AREA')
    key_light.energy = 2000
    key_light_obj = bpy.data.objects.new('KeyLight', key_light)
    key_light_obj.location = (2.0, -2.5, 2.5)
    key_light_obj.rotation_euler = (math.radians(60), 0, math.radians(35))
    bpy.context.collection.objects.link(key_light_obj)

    fill_light = bpy.data.lights.new('FillLight', type='AREA')
    fill_light.energy = 900
    fill_obj = bpy.data.objects.new('FillLight', fill_light)
    fill_obj.location = (-2.5, -1.5, 1.8)
    fill_obj.rotation_euler = (math.radians(70), 0, math.radians(-35))
    bpy.context.collection.objects.link(fill_obj)

    rim_light = bpy.data.lights.new('RimLight', type='AREA')
    rim_light.energy = 600
    rim_obj = bpy.data.objects.new('RimLight', rim_light)
    rim_obj.location = (0.0, 2.5, 1.5)
    rim_obj.rotation_euler = (math.radians(120), 0, math.radians(180))
    bpy.context.collection.objects.link(rim_obj)

    return cam_obj


def point_camera(camera: bpy.types.Object, target: Vector):
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()


def compute_bounds(obj) -> dict:
    coords = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    xs = [c.x for c in coords]
    ys = [c.y for c in coords]
    zs = [c.z for c in coords]
    min_v = Vector((min(xs), min(ys), min(zs)))
    max_v = Vector((max(xs), max(ys), max(zs)))
    center = (min_v + max_v) * 0.5
    height = max_v.z - min_v.z
    return {
        'min': min_v,
        'max': max_v,
        'center': center,
        'height': height,
    }


def configure_camera_position(
    camera,
    center: Vector,
    height: float,
    angle: float,
    distance_scale: float,
    height_factor: float,
    look_factor: float,
):
    distance = max(height * distance_scale, 2.0)
    offset = Vector((math.sin(angle), -math.cos(angle), 0.0)) * distance
    location = center + offset
    location.z = center.z + height * height_factor
    camera.location = location
    point = center.copy()
    point.z = height * look_factor
    point_camera(camera, point)


def render_views(camera, avatar: str, snapshot_dir: Path, bounds: dict):
    bpy.context.scene.camera = camera

    configure_camera_position(
        camera,
        bounds['center'],
        bounds['height'],
        angle=0.0,
        distance_scale=1.65,
        height_factor=0.35,
        look_factor=0.45,
    )
    bpy.context.scene.render.filepath = str(snapshot_dir / f'{avatar}_front.png')
    bpy.ops.render.render(write_still=True)

    configure_camera_position(
        camera,
        bounds['center'],
        bounds['height'],
        angle=math.radians(28),
        distance_scale=1.45,
        height_factor=0.4,
        look_factor=0.5,
    )
    bpy.context.scene.render.filepath = str(snapshot_dir / f'{avatar}_threequarter.png')
    bpy.ops.render.render(write_still=True)


def export_outputs(avatar: str, mesh_obj, armature):
    avatar_dir = META_ROOT / avatar
    blend_dir = avatar_dir / 'Blend'
    fbx_dir = avatar_dir / 'FBX'
    snap_dir = avatar_dir / 'Snapshots'
    meta_dir = avatar_dir / 'Metadata'
    blend_dir.mkdir(parents=True, exist_ok=True)
    fbx_dir.mkdir(parents=True, exist_ok=True)
    snap_dir.mkdir(parents=True, exist_ok=True)
    meta_dir.mkdir(parents=True, exist_ok=True)

    blend_path = blend_dir / f'{avatar}_base.blend'
    fbx_path = fbx_dir / f'{avatar}_R15.fbx'
    rig_report_path = meta_dir / f'{avatar}_rig_report.json'

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    bpy.ops.object.select_all(action='DESELECT')
    mesh_obj.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = mesh_obj
    bpy.ops.export_scene.fbx(
        filepath=str(fbx_path),
        use_selection=True,
        add_leaf_bones=False,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Y',
        axis_up='Z',
    )

    validator.write_report(mesh_obj.name, armature.name, rig_report_path)

    return snap_dir


def process_avatar(avatar: str):
    metadata = load_metadata(avatar)
    style = prepare_style(avatar)
    mesh_obj, armature = duplicate_base(avatar)
    if mesh_obj is None:
        raise RuntimeError('Failed to duplicate base mesh')

    recenter_mesh_and_armature(mesh_obj, armature)

    apply_head_style(mesh_obj, style['head'])
    apply_torso_style(mesh_obj, style['torso'])
    apply_limb_style(mesh_obj, style['limbs'])

    target_height = metadata.get('stud_height', 5.6)
    ap._scale_height(mesh_obj, target_height)

    ensure_skin_material(mesh_obj, avatar)
    bounds = compute_bounds(mesh_obj)
    camera = setup_environment()
    snapshot_dir = export_outputs(avatar, mesh_obj, armature)
    render_views(camera, avatar, snapshot_dir, bounds)


def parse_args():
    parser = argparse.ArgumentParser(description='Build avatar variant from R15 base')
    parser.add_argument('--avatar', required=True, help='Avatar identifier')
    return parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])


def main():
    args = parse_args()
    process_avatar(args.avatar)


if __name__ == '__main__':
    main()
