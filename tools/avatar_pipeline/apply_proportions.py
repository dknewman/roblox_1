#!/usr/bin/env python3
"""Applies proportion + skin metadata to duplicate Roblox R15 meshes inside Blender.

Example:
    blender master.blend --python tools/avatar_pipeline/apply_proportions.py -- \
        --source-mesh R15_Base --avatars Blonde BrunetteBlack LeaderPink LilacBucket
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from statistics import mean
from typing import Dict, Iterable, List, Sequence

STUD_TO_METERS = 0.28

try:
    import bpy  # type: ignore
except ModuleNotFoundError as exc:  # pragma: no cover - Blender runtime only
    bpy = None  # type: ignore
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _require_bpy() -> None:
    if bpy is None:
        raise RuntimeError(
            "bpy is unavailable. Run this script from Blender (" f"{_IMPORT_ERROR})"
        )


def _get_object(name: str):
    _require_bpy()
    obj = bpy.data.objects.get(name)
    if obj is None:
        raise RuntimeError(f"Object '{name}' not found in current blend")
    return obj


def _duplicate_mesh(source, target_name: str):
    mesh_copy = source.data.copy()
    obj_copy = source.copy()
    obj_copy.data = mesh_copy
    obj_copy.name = target_name
    mesh_copy.name = f"{target_name}_mesh"
    bpy.context.collection.objects.link(obj_copy)
    return obj_copy


def _vertex_indices_for_group(obj, group_name: str, weight_threshold: float = 0.15) -> List[int]:
    vg = obj.vertex_groups.get(group_name)
    if vg is None:
        raise RuntimeError(f"Vertex group '{group_name}' missing on {obj.name}")
    indices = []
    for v in obj.data.vertices:
        for g in v.groups:
            if g.group == vg.index and g.weight >= weight_threshold:
                indices.append(v.index)
                break
    return indices


def _measure_axis(obj, indices: Sequence[int], axis: str) -> float:
    if not indices:
        return 0.0
    axis_idx = "XYZ".index(axis.upper())
    coords = [obj.data.vertices[i].co[axis_idx] for i in indices]
    return max(coords) - min(coords)


def _scale_vertices(obj, indices: Sequence[int], axis: str, scale: float) -> None:
    if not indices or abs(scale - 1.0) < 1e-4:
        return
    axis_idx = "XYZ".index(axis.upper())
    values = [obj.data.vertices[i].co[axis_idx] for i in indices]
    center = mean(values)
    for vid in indices:
        vert = obj.data.vertices[vid]
        vec = vert.co.copy()
        vec[axis_idx] = center + (vec[axis_idx] - center) * scale
        vert.co = vec


def _scale_height(obj, target_studs: float) -> None:
    if target_studs <= 0:
        return
    verts = obj.data.vertices
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)
    current_height = max_z - min_z
    target_height = target_studs * STUD_TO_METERS
    if current_height <= 0:
        return
    factor = target_height / current_height
    if abs(factor - 1.0) < 1e-4:
        return
    for vert in verts:
        vert.co.z = min_z + (vert.co.z - min_z) * factor


def _paint_skin(obj, skin_rgb: Sequence[int]) -> None:
    colors = [channel / 255.0 for channel in skin_rgb]
    rgba = (*colors, 1.0)
    mesh = obj.data
    attr = mesh.color_attributes.get("VC_Skin")
    if attr is None:
        attr = mesh.color_attributes.new(name="VC_Skin", domain='CORNER', type='BYTE_COLOR')
    for loop in mesh.loops:
        attr.data[loop.index].color = rgba


def _load_metadata(root: Path, avatar: str) -> Dict[str, object]:
    meta_path = root / avatar / "Metadata" / f"{avatar}_proportions.json"
    skin_path = root / avatar / "Metadata" / f"{avatar}_skin.json"
    meta = json.loads(meta_path.read_text())
    skin = json.loads(skin_path.read_text()) if skin_path.exists() else None
    return {"proportions": meta, "skin": skin}


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def process_avatar(source_mesh_name: str, avatar: str, meta_root: Path) -> None:
    source = _get_object(source_mesh_name)
    avatar_obj = _duplicate_mesh(source, avatar)

    meta = _load_metadata(meta_root, avatar)
    props = meta["proportions"]

    target_height = float(props.get("stud_height", 5.6))
    shoulder_target = float(props.get("shoulder_width_studs", 1.1))
    hip_target = float(props.get("hip_width_studs", 1.0))

    _scale_height(avatar_obj, target_height)

    shoulder_indices = _vertex_indices_for_group(avatar_obj, "UpperTorso")
    hip_indices = _vertex_indices_for_group(avatar_obj, "LowerTorso")

    def _ratio(indices, target_studs):
        current = _measure_axis(avatar_obj, indices, 'X')
        target = target_studs * STUD_TO_METERS
        return (target / current) if current > 0 else 1.0

    _scale_vertices(avatar_obj, shoulder_indices, 'X', _ratio(shoulder_indices, shoulder_target))
    _scale_vertices(avatar_obj, hip_indices, 'X', _ratio(hip_indices, hip_target))

    skin = meta.get("skin")
    if skin:
        _paint_skin(avatar_obj, skin["skin_rgb"])

    avatar_obj.data.update()
    print(f"[avatar_pipeline] Applied proportions to {avatar}")


def parse_args(argv: Iterable[str]):
    parser = argparse.ArgumentParser(description="Apply avatar proportions to R15 mesh")
    parser.add_argument("--source-mesh", required=True, help="Name of the base R15 mesh object")
    parser.add_argument("--avatars", nargs="+", required=True, help="Avatar identifiers")
    parser.add_argument(
        "--meta-root",
        default="Assets/Characters",
        type=Path,
        help="Root directory that holds avatar metadata",
    )
    return parser.parse_args(list(argv))


def main(argv: Iterable[str]) -> None:
    args = parse_args(argv)
    for avatar in args.avatars:
        process_avatar(args.source_mesh, avatar, args.meta_root)


if __name__ == "__main__":  # pragma: no cover
    import sys

    main(sys.argv[1:])
