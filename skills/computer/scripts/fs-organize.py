#!/usr/bin/env python3
"""Organize files into subfolders by strategy.

usage:
  fs-organize.py [--dry-run] [--by smart|extension|date] [--dest DIR] [--plan PATH] <source-dir>
  fs-organize.py --apply [PLAN]
  fs-organize.py --undo [PLAN]

strategies:
  smart      Screenshots / Images / Documents / Archives / Videos / Audio / Code / Misc
  extension  one folder per file extension
  date       YYYY-MM from mtime

Plan/apply/undo:
  Scan writes ~/.tcu/last-organize-plan.json as status=planned *before* any moves,
  then applies and updates status. --apply / --undo use that plan (or PATH).

Respects TCU_SAFE_MODE=1 (forces dry-run on scan; blocks --apply/--undo).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

PLAN_VERSION = 1
PLAN_KIND = "organize"
Status = Literal["planned", "applied", "undone", "failed"]
Move = tuple[Path, Path, str]  # from, to, category (category is display-only)
Pair = tuple[Path, Path]
Error = dict[str, str]


def env_safe_mode() -> bool:
    return os.environ.get("TCU_SAFE_MODE", "").strip().lower() in (
        "1",
        "true",
        "yes",
        "y",
    )


def state_dir() -> Path:
    raw = os.environ.get("TCU_STATE_DIR", "").strip()
    if raw:
        return Path(raw).expanduser()
    return Path.home() / ".tcu"


def default_plan_path() -> Path:
    return state_dir() / "last-organize-plan.json"


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
        description="Organize files into subfolders (smart | extension | date). "
        "Supports plan/apply/undo via ~/.tcu/last-organize-plan.json."
    )
    p.add_argument(
        "source",
        nargs="?",
        type=Path,
        default=None,
        help="Directory to organize (scan mode)",
    )
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
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Plan only (also forced when TCU_SAFE_MODE=1)",
    )
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
    p.add_argument(
        "--plan",
        type=Path,
        default=None,
        metavar="PATH",
        help="Also write plan JSON to PATH (scan mode)",
    )
    p.add_argument(
        "--apply",
        nargs="?",
        const="__default__",
        default=None,
        metavar="PATH",
        help="Apply moves from plan file (default: last-organize-plan.json)",
    )
    p.add_argument(
        "--undo",
        nargs="?",
        const="__default__",
        default=None,
        metavar="PATH",
        help="Undo moves from plan file (default: last-organize-plan.json)",
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


# --- plan I/O -----------------------------------------------------------------


def resolve_plan_arg(value: str | None) -> Path:
    if value is None or value == "__default__":
        return default_plan_path()
    return Path(value).expanduser().resolve()


def plan_write_paths(default: Path, extra: Path | None) -> list[Path]:
    paths = [default]
    if extra is not None and extra != default:
        paths.append(extra)
    return paths


def save_plan(plan: dict[str, Any], paths: list[Path]) -> None:
    text = json.dumps(plan, indent=2) + "\n"
    for path in paths:
        path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            os.chmod(path.parent, 0o700)
        except OSError:
            pass
        path.write_text(text, encoding="utf-8")


def load_plan(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise FileNotFoundError(f"plan not found: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("plan root must be an object")
    if data.get("version") != PLAN_VERSION:
        raise ValueError(
            f"unsupported plan version: {data.get('version')!r} (need {PLAN_VERSION})"
        )
    if data.get("kind") != PLAN_KIND:
        raise ValueError(f"unsupported plan kind: {data.get('kind')!r}")
    if not isinstance(data.get("moves"), list):
        raise ValueError("plan.moves must be a list")
    return data


def build_plan(
    *,
    by: str,
    source: Path,
    dest_root: Path,
    moves: list[Move],
    status: Status,
    errors: list[Error] | None = None,
) -> dict[str, Any]:
    doc: dict[str, Any] = {
        "version": PLAN_VERSION,
        "kind": PLAN_KIND,
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": status,
        "by": by,
        "source": str(source),
        "dest_root": str(dest_root),
        "moves": [
            {"from": str(src), "to": str(dst), "category": cat}
            for src, dst, cat in moves
        ],
    }
    if errors:
        doc["errors"] = errors
    return doc


def moves_from_plan(data: dict[str, Any]) -> list[Move]:
    out: list[Move] = []
    for m in data["moves"]:
        if not isinstance(m, dict):
            raise ValueError("each move must be an object")
        out.append((Path(m["from"]), Path(m["to"]), str(m.get("category") or "")))
    return out


def set_plan_status(
    data: dict[str, Any],
    status: Status,
    paths: list[Path],
    errors: list[Error] | None = None,
) -> None:
    data["status"] = status
    if errors:
        data["errors"] = errors
    else:
        data.pop("errors", None)
    save_plan(data, paths)


# --- move engine --------------------------------------------------------------


def run_moves(pairs: list[Pair]) -> list[Error]:
    """Move each src→dst. Idempotent if already at dst. Never overwrites."""
    errors: list[Error] = []
    for src, dst in pairs:
        src_e = src.exists()
        dst_e = dst.exists()
        if not src_e and dst_e:
            continue  # already applied
        if src_e and not dst_e:
            try:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(src), str(dst))
            except OSError as e:
                errors.append({"from": str(src), "to": str(dst), "reason": str(e)})
            continue
        if not src_e and not dst_e:
            errors.append(
                {"from": str(src), "to": str(dst), "reason": "source and dest missing"}
            )
            continue
        # both exist
        try:
            if src.resolve() == dst.resolve():
                continue
        except OSError:
            pass
        errors.append(
            {
                "from": str(src),
                "to": str(dst),
                "reason": "dest exists (refusing overwrite)",
            }
        )
    return errors


def print_errors(errors: list[Error], label: str) -> None:
    print(f"\nerror: {len(errors)} {label} failed", file=sys.stderr)
    for err in errors:
        print(f"  {err['from']} → {err['to']}: {err['reason']}", file=sys.stderr)


def print_receipt(
    *,
    source: str,
    dest_root: str,
    by: str,
    mode: str,
    n_moves: int,
    status: str,
    plan_file: Path,
    by_cat: dict[str, int] | None = None,
    lines: list[str] | None = None,
    skipped: list[tuple[str, str]] | None = None,
) -> None:
    print(f"source: {source}")
    print(f"dest:   {dest_root}")
    print(f"by:     {by}")
    print(f"mode:   {mode}")
    extra = f"  skipped: {len(skipped)}" if skipped else ""
    print(f"plan:   {n_moves} move(s){extra}")
    print(f"status: {status}")
    print(f"plan_file: {plan_file}")
    if by_cat:
        print("by category:", dict(sorted(by_cat.items())))
    if lines:
        print()
        for line in lines:
            print(line)
    if skipped and len(skipped) <= 30:
        print("\nskipped:")
        for name, reason in skipped:
            print(f"  {name}  ({reason})")


def move_lines(moves: list[Move], *, reverse: bool = False) -> list[str]:
    seq = reversed(moves) if reverse else moves
    lines: list[str] = []
    for src, dst, cat in seq:
        a, b = (dst, src) if reverse else (src, dst)
        lines.append(f"  [{cat}] {a.name}  →  {b}")
    return lines


# --- commands -----------------------------------------------------------------


def cmd_apply(plan_path: Path) -> int:
    if env_safe_mode():
        print("error: TCU_SAFE_MODE=1 blocks apply", file=sys.stderr)
        return 1
    try:
        data = load_plan(plan_path)
        moves = moves_from_plan(data)
    except (OSError, ValueError, json.JSONDecodeError, FileNotFoundError, KeyError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    paths = [plan_path]
    if not moves:
        print_receipt(
            source=str(data.get("source", "")),
            dest_root=str(data.get("dest_root", "")),
            by=str(data.get("by", "")),
            mode="APPLY",
            n_moves=0,
            status=str(data.get("status", "")),
            plan_file=plan_path,
        )
        print("nothing to do")
        return 0

    errors = run_moves([(src, dst) for src, dst, _ in moves])
    status: Status = "failed" if errors else "applied"
    set_plan_status(data, status, paths, errors if errors else None)

    print_receipt(
        source=str(data.get("source", "")),
        dest_root=str(data.get("dest_root", "")),
        by=str(data.get("by", "")),
        mode="APPLY",
        n_moves=len(moves),
        status=status,
        plan_file=plan_path,
        lines=move_lines(moves),
    )
    if errors:
        print_errors(errors, "move(s)")
        return 1
    print(f"\napplied {len(moves)} move(s)")
    return 0


def cmd_undo(plan_path: Path) -> int:
    if env_safe_mode():
        print("error: TCU_SAFE_MODE=1 blocks undo", file=sys.stderr)
        return 1
    try:
        data = load_plan(plan_path)
        moves = moves_from_plan(data)
    except (OSError, ValueError, json.JSONDecodeError, FileNotFoundError, KeyError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    status_in = data.get("status")
    if status_in not in ("applied", "failed"):
        print(
            f"error: cannot undo plan with status={status_in!r} (need applied or failed)",
            file=sys.stderr,
        )
        return 1

    paths = [plan_path]
    if not moves:
        print_receipt(
            source=str(data.get("source", "")),
            dest_root=str(data.get("dest_root", "")),
            by=str(data.get("by", "")),
            mode="UNDO",
            n_moves=0,
            status=str(status_in),
            plan_file=plan_path,
        )
        print("nothing to do")
        return 0

    # reverse order, swap endpoints
    pairs: list[Pair] = [(dst, src) for src, dst, _ in reversed(moves)]
    errors = run_moves(pairs)
    status: Status = "failed" if errors else "undone"
    set_plan_status(data, status, paths, errors if errors else None)

    print_receipt(
        source=str(data.get("source", "")),
        dest_root=str(data.get("dest_root", "")),
        by=str(data.get("by", "")),
        mode="UNDO",
        n_moves=len(moves),
        status=status,
        plan_file=plan_path,
        lines=move_lines(moves, reverse=True),
    )
    if errors:
        print_errors(errors, "undo(s)")
        return 1
    print(f"\nundid {len(moves)} move(s)")
    return 0


def build_scan_moves(
    source: Path,
    dest_root: Path,
    by: str,
    include_hidden: bool,
    into_existing_only: bool,
) -> tuple[list[Move], list[tuple[str, str]]]:
    files = collect_files(source, by, include_hidden)
    moves: list[Move] = []
    planned: set[Path] = set()
    skipped: list[tuple[str, str]] = []

    for p in sorted(source.iterdir(), key=lambda x: x.name.lower()):
        if p.is_dir() and by == "smart":
            skipped.append((p.name + "/", "existing folder (left alone)"))

    for f in files:
        key = group_for(f, by)
        if key is None:
            skipped.append((f.name, "no category"))
            continue
        cat_dir = dest_root / key
        if into_existing_only and not cat_dir.is_dir():
            skipped.append((f.name, f"category {key} missing"))
            continue
        dest = unique_dest(cat_dir / f.name, planned)
        if dest.resolve() == f.resolve():
            continue
        planned.add(dest)
        moves.append((f, dest, key))
    return moves, skipped


def cmd_scan(args: argparse.Namespace) -> int:
    dry_run = bool(args.dry_run)
    if env_safe_mode() and not dry_run:
        print("TCU_SAFE_MODE=1 → forcing dry-run", file=sys.stderr)
        dry_run = True

    if args.source is None:
        print(
            "error: source directory required (or use --apply / --undo)",
            file=sys.stderr,
        )
        return 1

    source = args.source.expanduser().resolve()
    if not source.is_dir():
        print(f"error: not a directory: {source}", file=sys.stderr)
        return 1

    home = Path.home().resolve()
    if source in (Path("/").resolve(), home):
        print(f"error: refusing to organize unsafe path: {source}", file=sys.stderr)
        return 1

    dest_root = args.dest.expanduser().resolve() if args.dest else source
    moves, skipped = build_scan_moves(
        source,
        dest_root,
        args.by,
        args.include_hidden,
        args.into_existing_only,
    )

    default_path = default_plan_path()
    extra = args.plan.expanduser().resolve() if args.plan else None
    paths = plan_write_paths(default_path, extra)

    by_cat: dict[str, int] = defaultdict(int)
    for _, _, c in moves:
        by_cat[c] += 1

    # Always persist planned first so a crash mid-move still has an undo map.
    doc = build_plan(
        by=args.by,
        source=source,
        dest_root=dest_root,
        moves=moves,
        status="planned",
    )
    save_plan(doc, paths)

    if not moves:
        print_receipt(
            source=str(source),
            dest_root=str(dest_root),
            by=args.by,
            mode="DRY-RUN" if dry_run else "EXECUTE",
            n_moves=0,
            status="planned",
            plan_file=default_path,
            skipped=skipped,
        )
        print("nothing to do")
        return 0

    if dry_run:
        print_receipt(
            source=str(source),
            dest_root=str(dest_root),
            by=args.by,
            mode="DRY-RUN",
            n_moves=len(moves),
            status="planned",
            plan_file=default_path,
            by_cat=dict(by_cat),
            lines=move_lines(moves),
            skipped=skipped,
        )
        print(f"\n[dry-run] would move {len(moves)} file(s)")
        print(f"plan written: {default_path}")
        return 0

    errors = run_moves([(src, dst) for src, dst, _ in moves])
    status: Status = "failed" if errors else "applied"
    set_plan_status(doc, status, paths, errors if errors else None)

    print_receipt(
        source=str(source),
        dest_root=str(dest_root),
        by=args.by,
        mode="EXECUTE",
        n_moves=len(moves),
        status=status,
        plan_file=default_path,
        by_cat=dict(by_cat),
        lines=move_lines(moves),
        skipped=skipped,
    )
    if errors:
        print_errors(errors, "move(s)")
        return 1
    print(f"\nmoved {len(moves)} file(s)")
    print(f"plan written: {default_path}")
    print("undo: python3 fs-organize.py --undo")
    return 0


def main() -> int:
    args = parse_args()
    apply_set = args.apply is not None
    undo_set = args.undo is not None

    if apply_set and undo_set:
        print("error: use only one of --apply or --undo", file=sys.stderr)
        return 1
    if (apply_set or undo_set) and args.source is not None:
        print(
            "error: --apply/--undo cannot be combined with a source directory",
            file=sys.stderr,
        )
        return 1
    if apply_set:
        return cmd_apply(resolve_plan_arg(args.apply))
    if undo_set:
        return cmd_undo(resolve_plan_arg(args.undo))
    return cmd_scan(args)


if __name__ == "__main__":
    raise SystemExit(main())
