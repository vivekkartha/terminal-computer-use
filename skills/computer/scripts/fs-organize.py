#!/usr/bin/env python3
"""Organize files in a directory into subfolders by extension (or date).

usage:
  fs-organize.py [--dry-run] [--by extension|date] [--dest DIR] <source-dir>
"""
from __future__ import annotations

import argparse
import shutil
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Organize files into subfolders by extension or modification date."
    )
    p.add_argument("source", type=Path, help="Directory to organize")
    p.add_argument(
        "--dest",
        type=Path,
        default=None,
        help="Destination root (default: same as source)",
    )
    p.add_argument(
        "--by",
        choices=("extension", "date"),
        default="extension",
        help="Grouping strategy (default: extension)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned moves without changing disk",
    )
    p.add_argument(
        "--include-hidden",
        action="store_true",
        help="Include dotfiles",
    )
    return p.parse_args()


def group_key(path: Path, strategy: str) -> str:
    if strategy == "extension":
        ext = path.suffix.lower().lstrip(".")
        return ext if ext else "_no_extension"
    # date: YYYY-MM
    mtime = datetime.fromtimestamp(path.stat().st_mtime)
    return mtime.strftime("%Y-%m")


def main() -> int:
    args = parse_args()
    source = args.source.expanduser().resolve()
    if not source.is_dir():
        print(f"error: not a directory: {source}", file=sys.stderr)
        return 1

    dest_root = (args.dest.expanduser().resolve() if args.dest else source)

    files = [
        f
        for f in source.iterdir()
        if f.is_file() and (args.include_hidden or not f.name.startswith("."))
    ]

    if not files:
        print(f"no files to organize in {source}")
        return 0

    plan: dict[str, list[Path]] = defaultdict(list)
    for f in files:
        plan[group_key(f, args.by)].append(f)

    moves: list[tuple[Path, Path]] = []
    for key, group in sorted(plan.items()):
        target_dir = dest_root / key
        for f in group:
            dest = target_dir / f.name
            if dest.resolve() == f.resolve():
                continue
            # collision: append counter
            if dest.exists() or any(d == dest for _, d in moves):
                stem, suffix = f.stem, f.suffix
                n = 1
                while True:
                    candidate = target_dir / f"{stem}-{n}{suffix}"
                    if not candidate.exists() and not any(d == candidate for _, d in moves):
                        dest = candidate
                        break
                    n += 1
            moves.append((f, dest))

    if not moves:
        print("nothing to move")
        return 0

    print(f"{'[dry-run] ' if args.dry_run else ''}organizing {len(moves)} file(s) in {source}")
    for src, dst in moves:
        print(f"  {src.name} → {dst.relative_to(dest_root) if dest_root in dst.parents or dst.parent == dest_root else dst}")
        if not args.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))

    if args.dry_run:
        print(f"[dry-run] would move {len(moves)} file(s)")
    else:
        print(f"moved {len(moves)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
