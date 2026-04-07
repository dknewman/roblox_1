#!/usr/bin/env python3
"""Extracts avatar proportions from Grease Pencil annotations.

Usage:
    blender -b AvatarRefs.blend --python tools/avatar_pipeline/extract_proportions.py -- \
        --avatar FrontLeft --output Assets/Characters/FrontLeft/Metadata/FrontLeft_proportions.json

Prereqs:
- Each landmark is drawn inside a Grease Pencil layer named `L_<NAME>` with exactly two
  points (start/end). Example: `L_head_height`, `L_shoulder_width`.
- Scene scale uses meters; conversion to studs uses the STUD_TO_METERS constant.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable

try:
    import bpy  # type: ignore
except ModuleNotFoundError as exc:  # pragma: no cover - Blender only
    bpy = None  # type: ignore
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None

STUD_TO_METERS = 0.28


@dataclass
class Landmark:
    name: str
    length_m: float

    @property
    def length_studs(self) -> float:
        return self.length_m / STUD_TO_METERS


def _require_bpy() -> None:
    if bpy is None:
        raise RuntimeError(
            "bpy is unavailable; run inside Blender (" f"{_IMPORT_ERROR})"
        )


def _collect_landmarks() -> Dict[str, Landmark]:
    _require_bpy()
    landmarks: Dict[str, Landmark] = {}
    for gp in bpy.data.grease_pencils:
        for layer in gp.layers:
            if not layer.info.startswith("L_"):
                continue
            frame = layer.active_frame
            if not frame or len(frame.strokes) == 0:
                continue
            stroke = frame.strokes[0]
            if len(stroke.points) < 2:
                continue
            p0, p1 = stroke.points[0], stroke.points[-1]
            length = (p0.co - p1.co).length
            name = layer.info[2:]
            landmarks[name] = Landmark(name=name, length_m=length)
    return landmarks


def _export(avatar: str, landmarks: Dict[str, Landmark], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "avatar": avatar,
        "unit_scale": {
            "stud_to_m": STUD_TO_METERS,
            "scene_unit": "METERS",
        },
        "landmarks": {
            name: {
                "length_m": lm.length_m,
                "length_studs": lm.length_studs,
            }
            for name, lm in sorted(landmarks.items())
        },
    }
    output.write_text(json.dumps(payload, indent=2))
    print(f"[avatar_pipeline] Wrote proportions to {output}")


def parse_args(argv: Iterable[str]):
    parser = argparse.ArgumentParser(description="Export avatar proportions")
    parser.add_argument("--avatar", required=True, help="Avatar identifier")
    parser.add_argument("--output", required=True, help="Target JSON path")
    return parser.parse_args(list(argv))


def main(argv: Iterable[str]) -> None:
    args = parse_args(argv)
    landmarks = _collect_landmarks()
    if not landmarks:
        raise RuntimeError("No Grease Pencil layers named 'L_*' were found")
    _export(args.avatar, landmarks, Path(args.output))


if __name__ == "__main__":  # pragma: no cover
    import sys

    main(sys.argv[1:])
