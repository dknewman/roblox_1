#!/usr/bin/env python3
"""Generates a simplified Roblox-style R15 base mesh + armature."""
from __future__ import annotations

import math
from pathlib import Path

import bpy
import mathutils

REPO_ROOT = Path(bpy.path.abspath('//'))
OUTPUT_BLEND = REPO_ROOT / 'Assets/RobloxTemplates/R15_Base.blend'
OUTPUT_FBX = REPO_ROOT / 'Assets/RobloxTemplates/R15_Base.fbx'

STUD = 0.28
HEIGHT_STUDS = 5.6
TOTAL_HEIGHT = STUD * HEIGHT_STUDS


def reset_scene() -> None:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)


def add_cube(location, scale):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.scale = scale
    return obj


def add_cylinder(location, radius, depth, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cylinder_add(location=location, radius=radius, depth=depth, rotation=rotation)
    return bpy.context.active_object


def add_sphere(location, radius):
    bpy.ops.mesh.primitive_uv_sphere_add(location=location, radius=radius, segments=32, ring_count=16)
    return bpy.context.active_object


def build_body_mesh():
    pieces = []
    hip_height = 0.35
    torso_height = 0.6
    upper_torso_height = 0.55
    head_center = hip_height + torso_height + upper_torso_height + 0.2

    pieces.append(add_cube((0, 0, hip_height), (0.35, 0.22, torso_height / 2)))
    pieces.append(add_cube((0, 0, hip_height + torso_height), (0.4, 0.25, upper_torso_height / 2)))

    pieces.append(add_sphere((0, 0, head_center), 0.22))

    arm_y = 0.0
    shoulder_z = hip_height + torso_height + 0.35
    arm_radius = 0.09
    upper_arm = 0.45
    lower_arm = 0.4
    for side in (-1, 1):
        x = 0.42 * side
        pieces.append(add_cylinder((x, arm_y, shoulder_z), arm_radius, upper_arm, rotation=(0, math.pi / 2, 0)))
        pieces.append(add_cylinder((x + 0.25 * side, arm_y, shoulder_z - 0.25), arm_radius * 0.95, lower_arm, rotation=(0, math.pi / 2, 0)))
        pieces.append(add_sphere((x + 0.45 * side, arm_y, shoulder_z - 0.45), arm_radius * 0.9))

    leg_radius = 0.11
    upper_leg = 0.55
    lower_leg = 0.52
    foot_length = 0.32
    foot_height = 0.1
    for side in (-1, 1):
        x = 0.18 * side
        mid = upper_leg / 2
        pieces.append(add_cylinder((x, 0, mid), leg_radius, upper_leg))
        pieces.append(add_cylinder((x, 0, -lower_leg / 2), leg_radius * 0.95, lower_leg))
        pieces.append(add_cube((x + 0.05 * side, 0, -lower_leg - foot_height / 2), (foot_length / 2, 0.13, foot_height / 2)))

    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = 'R15_Base'
    mesh_obj.data.name = 'R15_BaseMesh'
    bpy.ops.object.shade_smooth()
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    import mathutils
    coords = [mesh_obj.matrix_world @ mathutils.Vector(corner) for corner in mesh_obj.bound_box]
    min_z = min(c.z for c in coords)
    mesh_obj.location.z -= min_z
    return mesh_obj


def build_armature():
    arm_data = bpy.data.armatures.new('R15_ArmatureData')
    arm_obj = bpy.data.objects.new('R15_Armature', arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='EDIT')

    bones = (
        ('HumanoidRootPart', None, (0, 0, -0.05), (0, 0, 0.15)),
        ('LowerTorso', 'HumanoidRootPart', (0, 0, 0.15), (0, 0, 0.55)),
        ('UpperTorso', 'LowerTorso', (0, 0, 0.55), (0, 0, 0.95)),
        ('Head', 'UpperTorso', (0, 0, 0.95), (0, 0, 1.35)),
        ('LeftUpperArm', 'UpperTorso', (0.2, 0, 0.9), (0.5, 0, 0.85)),
        ('LeftLowerArm', 'LeftUpperArm', (0.5, 0, 0.85), (0.65, 0, 0.65)),
        ('LeftHand', 'LeftLowerArm', (0.65, 0, 0.65), (0.7, 0, 0.5)),
        ('RightUpperArm', 'UpperTorso', (-0.2, 0, 0.9), (-0.5, 0, 0.85)),
        ('RightLowerArm', 'RightUpperArm', (-0.5, 0, 0.85), (-0.65, 0, 0.65)),
        ('RightHand', 'RightLowerArm', (-0.65, 0, 0.65), (-0.7, 0, 0.5)),
        ('LeftUpperLeg', 'LowerTorso', (0.1, 0, 0.2), (0.1, 0, -0.1)),
        ('LeftLowerLeg', 'LeftUpperLeg', (0.1, 0, -0.1), (0.1, 0, -0.45)),
        ('LeftFoot', 'LeftLowerLeg', (0.1, 0, -0.45), (0.25, 0, -0.55)),
        ('RightUpperLeg', 'LowerTorso', (-0.1, 0, 0.2), (-0.1, 0, -0.1)),
        ('RightLowerLeg', 'RightUpperLeg', (-0.1, 0, -0.1), (-0.1, 0, -0.45)),
        ('RightFoot', 'RightLowerLeg', (-0.1, 0, -0.45), (-0.25, 0, -0.55)),
    )

    edit_bones = arm_data.edit_bones
    name_to_bone = {}
    for name, parent_name, head, tail in bones:
        bone = edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        if parent_name:
            bone.parent = edit_bones[parent_name]
        name_to_bone[name] = bone

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj


def parent_mesh_to_armature(mesh_obj, arm_obj):
    bpy.ops.object.select_all(action='DESELECT')
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')


def ensure_output_dirs():
    OUTPUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FBX.parent.mkdir(parents=True, exist_ok=True)


def save_assets(mesh_obj, arm_obj):
    ensure_output_dirs()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_BLEND))

    bpy.ops.object.select_all(action='DESELECT')
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_obj
    bpy.ops.export_scene.fbx(
        filepath=str(OUTPUT_FBX),
        use_selection=True,
        add_leaf_bones=False,
        axis_forward='-Y',
        axis_up='Z',
        apply_scale_options='FBX_SCALE_ALL',
    )


def main():
    reset_scene()
    mesh_obj = build_body_mesh()
    arm_obj = build_armature()
    parent_mesh_to_armature(mesh_obj, arm_obj)
    save_assets(mesh_obj, arm_obj)


if __name__ == '__main__':
    main()
