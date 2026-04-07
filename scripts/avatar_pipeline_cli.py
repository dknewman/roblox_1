#!/usr/bin/env python3
"""Command-line helper for avatar pipeline asset prep."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable

MANIFEST_PATH = Path("references/reference_manifest.json")


def cmd_manifest(_: argparse.Namespace) -> None:
    data = json.loads(MANIFEST_PATH.read_text())
    print(json.dumps(data, indent=2))


def cmd_summary(_: argparse.Namespace) -> None:
    if not MANIFEST_PATH.exists():
        raise SystemExit("Manifest missing. Run manifest generation step first.")
    data = json.loads(MANIFEST_PATH.read_text())
    rows = [
        f"- {entry['id']}: {entry['width']}x{entry['height']} ({entry['status']})"
        for entry in data.get("references", [])
    ]
    print("Reference Summary\n" + "\n".join(rows))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Avatar pipeline helper")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub_manifest = sub.add_parser("manifest", help="Print raw manifest JSON")
    sub_manifest.set_defaults(func=cmd_manifest)

    sub_summary = sub.add_parser("summary", help="Readable reference info")
    sub_summary.set_defaults(func=cmd_summary)

    return parser


def main(argv: Iterable[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    args.func(args)


if __name__ == "__main__":
    import sys

    main(sys.argv[1:])
