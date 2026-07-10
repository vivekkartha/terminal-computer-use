#!/usr/bin/env python3
"""Unit tests for fs-smart-organize.py using a temp fixture."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "computer" / "scripts" / "fs-smart-organize.py"


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="tcu-test-") as td:
        root = Path(td)
        (root / "Screenshot 2026-01-01 at 12.00.00 AM.png").write_bytes(b"png")
        (root / "receipt.jpg").write_bytes(b"jpg")
        (root / "notes.pdf").write_bytes(b"pdf")
        (root / "archive.zip").write_bytes(b"zip")
        (root / ".hidden").write_bytes(b"x")
        (root / ".localized").write_bytes(b"")

        dry = run(["--dry-run", str(root)])
        assert dry.returncode == 0, dry.stderr
        assert "Screenshots" in dry.stdout
        assert "Images" in dry.stdout
        assert "Documents" in dry.stdout
        assert "Archives" in dry.stdout
        assert (root / "receipt.jpg").exists(), "dry-run must not move"

        exe = run([str(root)])
        assert exe.returncode == 0, exe.stderr
        assert (root / "Screenshots" / "Screenshot 2026-01-01 at 12.00.00 AM.png").exists()
        assert (root / "Images" / "receipt.jpg").exists()
        assert (root / "Documents" / "notes.pdf").exists()
        assert (root / "Archives" / "archive.zip").exists()
        assert (root / ".localized").exists(), "must skip .localized"
        assert not (root / "receipt.jpg").exists()

        # idempotent second run
        again = run([str(root)])
        assert again.returncode == 0, again.stderr

    print("test_fs_smart_organize: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
