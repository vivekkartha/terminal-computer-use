#!/usr/bin/env python3
"""Organize files into subfolders by strategy.

usage:
  fs-organize.py [--dry-run] [--by smart|extension|date] [--dest DIR] <source-dir>

strategies:
  smart      Screenshots / Images / Documents / Archives / Videos / Audio / Code / Misc
  extension  one folder per file extension
  date       YYYY-MM from mtime
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

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

# category folder names created by --by smart (left alone on re-run)
SMART_CATEGORY_DIRS = {
    "Screenshots", "Images", "Documents", "Archives",
    "Videos", "Audio", "Code", "Misc",
}


def smart_category(path: Path) -> str | None:
    name = path.name
    if name in SKIP_NAMES or name.startswith("."):
        return None
    if path.is_dir():
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
    return "Misc"


def extension_key(path: Path) -> str:
    ext = path.suffix.lower().lstrip(".")
    return ext if ext else "_no_extension"


def date_key(path: Path) -> str:
    mtime = datetime.fromtimestamp(path.stat().st_mtime)
    return mtime.strftime("%Y-%m")


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
        description="Organize files into subfolders (smart | extension | date)."
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
        choices=("smart", "extension", "date"),
        default="smart",
        help="Grouping strategy (default: smart)",
    )
    p.add_argument("--dry-run", action="store_true", help="Plan only")
    p.add_argument(
        "--include-hidden",
        action="store_true",
        help="Include dotfiles (extension/date modes)",
    )
    p.add_argument(
        "--into-existing-only",
        action="store_true",
        help="Only move into category folders that already exist (smart mode)",
    )
    return p.parse_args()


def collect_files(source: Path, by: str, include_hidden: bool) -> list[Path]:
    items: list[Path] = []
    for p in sorted(source.iterdir(), key=lambda x: x.name.lower()):
        if p.name in SKIP_NAMES:
            continue
        if p.is_dir():
            continue
        if p.name.startswith(".") and not include_hidden:
            continue
        if by == "smart" and p.name.startswith("."):
            continue
        items.append(p)
    return items


def group_for(path: Path, by: str) -> str | None:
    if by == "smart":
        return smart_category(path)
    if by == "extension":
        return extension_key(path)
    if by == "date":
        return date_key(path)
    return None


def main() -> int:
    args = parse_args()
    source = args.source.expanduser().resolve()
    if not source.is_dir():
        print(f"error: not a directory: {source}", file=sys.stderr)
        return 1

    # Refuse organizing home or root
    home = Path.home().resolve()
    if source in (Path("/").resolve(), home):
        print(f"error: refusing to organize unsafe path: {source}", file=sys.stderr)
        return 1

    dest_root = args.dest.expanduser().resolve() if args.dest else source

    files = collect_files(source, args.by, args.include_hidden)
    plan: list[tuple[Path, Path, str]] = []
    planned: set[Path] = set()
    skipped: list[tuple[str, str]] = []

    # note skipped dirs for smart mode visibility
    for p in sorted(source.iterdir(), key=lambda x: x.name.lower()):
        if p.is_dir() and args.by == "smart":
            skipped.append((p.name + "/", "existing folder (left alone)"))

    for f in files:
        key = group_for(f, args.by)
        if key is None:
            skipped.append((f.name, "no category"))
            continue
        cat_dir = dest_root / key
        if args.into_existing_only and not cat_dir.is_dir():
            skipped.append((f.name, f"category {key} missing"))
            continue
        dest = unique_dest(cat_dir / f.name, planned)
        if dest.resolve() == f.resolve():
            continue
        planned.add(dest)
        plan.append((f, dest, key))

    by_cat: dict[str, int] = defaultdict(int)
    for _, _, c in plan:
        by_cat[c] += 1

    print(f"source: {source}")
    print(f"dest:   {dest_root}")
    print(f"by:     {args.by}")
    print(f"mode:   {'DRY-RUN' if args.dry_run else 'EXECUTE'}")
    print(f"plan:   {len(plan)} move(s)  skipped: {len(skipped)}")
    if by_cat:
        print("by category:", dict(sorted(by_cat.items())))
    print()
    for src, dst, cat in plan:
        try:
            rel = dst.relative_to(dest_root)
        except ValueError:
            rel = dst
        print(f"  [{cat}] {src.name}  →  {rel}")
    if skipped and len(skipped) <= 30:
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
