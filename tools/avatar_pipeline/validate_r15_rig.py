#!/usr/bin/env python3
"""Validates that an avatar mesh conforms to Roblox R15 rig expectations."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Iterable, List

try:
    import bpy  # type: ignore
except ModuleNotFoundError as exc:  # pragma: no cover - Blender only
    bpy = None  # type: ignore
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None

STUD_TO_METERS = 0.28
EXPECTED_BONES = {
    "HumanoidRootPart",
    "LowerTorso",
    "UpperTorso",
    "Head",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
}
EXPECTED_GROUPS = {
    "Head",
    "UpperTorso",
    "LowerTorso",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
}


def _require_bpy() -> None:
    if bpy is None:
        raise RuntimeError(
            "bpy is unavailable; run inside Blender (" f"{_IMPORT_ERROR})"
        )


def _get_obj(name: str, kind: str):
    _require_bpy()
    obj = bpy.data.objects.get(name)
    if obj is None:
        raise RuntimeError(f"{kind} object '{name}' not found")
    return obj


def _bone_lengths(armature) -> Dict[str, float]:
    lengths = {}
    for bone in armature.data.bones:
        lengths[bone.name] = bone.length
    return lengths


def evaluate(mesh, armature) -> Dict[str, object]:
    report: Dict[str, object] = {
        "bone_checks": {},
        "vertex_group_checks": {},
    }
    lengths = _bone_lengths(armature)
    for name in sorted(EXPECTED_BONES):
        length = lengths.get(name)
        report["bone_checks"][name] = {
            "present": length is not None,
            "length": length,
        }
    vg_names = {vg.name for vg in mesh.vertex_groups}
    missing_groups = sorted(EXPECTED_GROUPS - vg_names)
    report["vertex_group_checks"] = {
        "missing": missing_groups,
        "total": len(vg_names),
    }
    bbox = mesh.bound_box
    z_values = [corner[2] for corner in bbox]
    height_m = max(z_values) - min(z_values)
    report["bounding_box"] = {
        "height_m": height_m,
        "height_studs": height_m / STUD_TO_METERS,
    }
    return report


def generate_report(mesh_name: str, armature_name: str) -> Dict[str, object]:
    mesh = _get_obj(mesh_name, "Mesh")
    armature = _get_obj(armature_name, "Armature")
    return evaluate(mesh, armature)


def write_report(mesh_name: str, armature_name: str, output: Path) -> Dict[str, object]:
    report = generate_report(mesh_name, armature_name)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2))
    print(f"[avatar_pipeline] Validation report written to {output}")
    return report


def parse_args(argv: Iterable[str]):
    parser = argparse.ArgumentParser(description="Validate R15 rig");
    parser.add_argument("--mesh", required=True, help="Avatar mesh object name")
    parser.add_argument("--armature", required=True, help="Armature object name")
    parser.add_argument("--output", required=True, help="Report JSON")
    return parser.parse_args(list(argv))


def main(argv: Iterable[str]) -> None:
    args = parse_args(argv)
    write_report(args.mesh, args.armature, Path(args.output))


if __name__ == "__main__":  # pragma: no cover
    import sys

    main(sys.argv[1:])
