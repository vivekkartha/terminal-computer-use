#!/usr/bin/env python3
"""Smart-organize loose files into category folders (Desktop-friendly).

usage:
  fs-smart-organize.py [--dry-run] [--dest DIR] <source-dir>
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

# macOS / junk to never move
SKIP_NAMES = {
    ".DS_Store",
    ".localized",
    "Icon\r",
    "desktop.ini",
    "Thumbs.db",
}

SCREENSHOT_RE = re.compile(
    r"^(Screenshot|Screen Shot|CleanShot|Capture)\b",
    re.IGNORECASE,
)

IMAGE_EXT = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".heif",
    ".tiff", ".tif", ".bmp", ".raw", ".svg", ".ico",
}
DOC_EXT = {
    ".pdf", ".doc", ".docx", ".rtf", ".txt", ".md", ".pages",
    ".odt", ".xls", ".xlsx", ".csv", ".ppt", ".pptx", ".key", ".numbers",
}
ARCHIVE_EXT = {".zip", ".tar", ".gz", ".tgz", ".bz2", ".7z", ".rar", ".dmg", ".pkg"}
CODE_EXT = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".go", ".rs", ".rb", ".java",
    ".c", ".cpp", ".h", ".swift", ".kt", ".sh", ".zsh", ".json", ".yaml",
    ".yml", ".toml", ".xml", ".html", ".css", ".sql",
}
VIDEO_EXT = {".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm"}
AUDIO_EXT = {".mp3", ".wav", ".m4a", ".aac", ".flac", ".aiff", ".ogg"}


def category_for(path: Path) -> str | None:
    """Return destination folder name, or None to leave in place."""
    name = path.name
    if name in SKIP_NAMES or name.startswith("."):
        return None
    if path.is_dir():
        # Do not nest existing top-level folders
        return None

    ext = path.suffix.lower()
    if SCREENSHOT_RE.match(name) or "screenshot" in name.lower():
        return "Screenshots"
    if ext in IMAGE_EXT:
        return "Images"
    if ext in DOC_EXT:
        return "Documents"
    if ext in ARCHIVE_EXT:
        return "Archives"
    if ext in VIDEO_EXT:
        return "Videos"
    if ext in AUDIO_EXT:
        return "Audio"
    if ext in CODE_EXT:
        return "Code"
    if ext in {".app"} or path.suffix == "":
        # unknown / no extension — Misc
        return "Misc"
    return "Misc"


def unique_dest(dest: Path, planned: set[Path]) -> Path:
    if not dest.exists() and dest not in planned:
        return dest
    stem, suffix = dest.stem, dest.suffix
    n = 1
    while True:
        candidate = dest.with_name(f"{stem}-{n}{suffix}")
        if not candidate.exists() and candidate not in planned:
            return candidate
        n += 1


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Smart-organize files into Screenshots/Images/Documents/..."
    )
    p.add_argument("source", type=Path, help="Directory to organize (e.g. ~/Desktop)")
    p.add_argument(
        "--dest",
        type=Path,
        default=None,
        help="Root for category folders (default: same as source)",
    )
    p.add_argument("--dry-run", action="store_true", help="Plan only")
    p.add_argument(
        "--into-existing-only",
        action="store_true",
        help="Only move into category folders that already exist",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source.expanduser().resolve()
    if not source.is_dir():
        print(f"error: not a directory: {source}", file=sys.stderr)
        return 1
    dest_root = (args.dest.expanduser().resolve() if args.dest else source)

    plan: list[tuple[Path, Path, str]] = []
    planned_dests: set[Path] = set()
    skipped: list[tuple[str, str]] = []

    for p in sorted(source.iterdir(), key=lambda x: x.name.lower()):
        if p.name in SKIP_NAMES or (p.name.startswith(".") and p.is_file()):
            skipped.append((p.name, "system/hidden"))
            continue
        if p.is_dir():
            # Skip category dirs we own and any user folders
            skipped.append((p.name + "/", "existing folder (left alone)"))
            continue
        cat = category_for(p)
        if cat is None:
            skipped.append((p.name, "no category"))
            continue
        cat_dir = dest_root / cat
        if args.into_existing_only and not cat_dir.is_dir():
            skipped.append((p.name, f"category {cat} missing"))
            continue
        dest = unique_dest(cat_dir / p.name, planned_dests)
        planned_dests.add(dest)
        plan.append((p, dest, cat))

    by_cat: dict[str, int] = defaultdict(int)
    for _, _, c in plan:
        by_cat[c] += 1

    print(f"source: {source}")
    print(f"dest:   {dest_root}")
    print(f"mode:   {'DRY-RUN' if args.dry_run else 'EXECUTE'}")
    print(f"plan:   {len(plan)} move(s)  skipped: {len(skipped)}")
    if by_cat:
        print("by category:", dict(sorted(by_cat.items())))
    print()
    for src, dst, cat in plan:
        print(f"  [{cat}] {src.name}  →  {dst.relative_to(dest_root)}")
    if skipped and len(skipped) <= 20:
        print("\nskipped:")
        for name, reason in skipped:
            print(f"  {name}  ({reason})")

    if not plan:
        print("nothing to do")
        return 0

    if args.dry_run:
        print(f"\n[dry-run] would move {len(plan)} file(s)")
        return 0

    for src, dst, _ in plan:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
    print(f"\nmoved {len(plan)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
