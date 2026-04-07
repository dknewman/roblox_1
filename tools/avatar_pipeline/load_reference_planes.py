#!/usr/bin/env python3
"""Utility for spawning storyboard reference planes inside Blender.

Run from Blender's bundled Python (GUI or headless):

    blender -b master.blend --python tools/avatar_pipeline/load_reference_planes.py -- \
        --images references/reference_manifest.json --collection Reference --stud-height 5.8

The script reads either a JSON manifest (same structure as references/reference_manifest.json)
or a list of image file paths. Each plane is scaled so its height equals the provided
stud-height (converted to meters by 0.28 multiplier) and offset slightly along +Y so
multiple variants remain visible.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable, List

try:
    import bpy  # type: ignore
except ModuleNotFoundError as exc:  # pragma: no cover - Blender only
    bpy = None  # type: ignore
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None

STUD_TO_METERS = 0.28


def _require_bpy() -> None:
    if bpy is None:
        raise RuntimeError(
            "bpy is unavailable. Run this script inside Blender (" f"{_IMPORT_ERROR})"
        )


def _load_image_list(arg: str) -> List[Path]:
    manifest_path = Path(arg)
    if manifest_path.suffix.lower() == ".json":
        data = json.loads(manifest_path.read_text())
        images = [Path(entry["path"]) for entry in data.get("references", [])]
    else:
        images = [manifest_path]
    return [path.expanduser().resolve() for path in images]


def _ensure_collection(name: str):
    _require_bpy()
    collection = bpy.data.collections.get(name)
    if collection is None:
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
    return collection


def _create_scale_guide(height_studs: float) -> None:
    _require_bpy()
    guide_name = "ScaleGuide"
    height_m = height_studs * STUD_TO_METERS
    empty = bpy.data.objects.get(guide_name)
    if empty is None:
        empty = bpy.data.objects.new(guide_name, None)
        bpy.context.scene.collection.objects.link(empty)
    empty.empty_display_type = 'ARROWS'
    empty.scale = (1.0, 1.0, height_m)


def _spawn_plane(image_path: Path, idx: int, collection, height_studs: float) -> None:
    _require_bpy()
    if not image_path.exists():
        print(f"[avatar_pipeline] Skipping missing image {image_path}")
        return
    bpy.ops.mesh.primitive_plane_add(size=1.0)
    plane = bpy.context.active_object
    plane.name = f"RefPlane_{idx:02d}"
    plane.data.name = plane.name

    image = bpy.data.images.load(str(image_path), check_existing=True)
    mat = bpy.data.materials.new(name=f"Mat_{plane.name}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(bsdf.inputs['Base Color'], tex.outputs['Color'])
    plane.data.materials.append(mat)

    height_m = height_studs * STUD_TO_METERS
    aspect = image.size[0] / image.size[1]
    plane.scale = (height_m * aspect / 2, height_m / 2, 1)
    plane.location = (idx * 0.05, idx * 0.1, height_m / 2)
    collection.objects.link(plane)


def build_reference_scene(images: Iterable[Path], collection_name: str, height_studs: float) -> None:
    _require_bpy()
    collection = _ensure_collection(collection_name)
    _create_scale_guide(height_studs)
    for idx, image_path in enumerate(images):
        _spawn_plane(image_path, idx, collection, height_studs)


def parse_args(argv: Iterable[str]):
    parser = argparse.ArgumentParser(description="Load storyboard images as Blender planes")
    parser.add_argument(
        "--images",
        nargs="+",
        required=True,
        help="Either JSON manifest or list of PNG files",
    )
    parser.add_argument("--collection", default="Reference", help="Target Blender collection")
    parser.add_argument(
        "--stud-height", type=float, default=5.8, help="Target avatar height in studs"
    )
    return parser.parse_args(list(argv))


def main(argv: Iterable[str]) -> None:
    args = parse_args(argv)
    image_paths: List[Path] = []
    for item in args.images:
        image_paths.extend(_load_image_list(item))
    build_reference_scene(image_paths, args.collection, args.stud_height)


if __name__ == "__main__":  # pragma: no cover - Blender entry point
    import sys

    main(sys.argv[1:])
