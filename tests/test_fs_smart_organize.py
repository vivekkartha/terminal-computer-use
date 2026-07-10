#!/usr/bin/env python3
"""Unit tests for fs-organize.py (smart + extension)."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "computer" / "scripts" / "fs-organize.py"
SHIM = ROOT / "skills" / "computer" / "scripts" / "fs-smart-organize.py"


def run(args: list[str], script: Path = SCRIPT) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(script), *args],
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

        dry = run(["--dry-run", "--by", "smart", str(root)])
        assert dry.returncode == 0, dry.stderr + dry.stdout
        assert "Screenshots" in dry.stdout
        assert "Images" in dry.stdout
        assert (root / "receipt.jpg").exists(), "dry-run must not move"

        exe = run(["--by", "smart", str(root)])
        assert exe.returncode == 0, exe.stderr + exe.stdout
        assert (root / "Screenshots" / "Screenshot 2026-01-01 at 12.00.00 AM.png").exists()
        assert (root / "Images" / "receipt.jpg").exists()
        assert (root / "Documents" / "notes.pdf").exists()
        assert (root / "Archives" / "archive.zip").exists()
        assert (root / ".localized").exists()

        # shim
        with tempfile.TemporaryDirectory(prefix="tcu-shim-") as td2:
            r2 = Path(td2)
            (r2 / "Screenshot x.png").write_bytes(b"p")
            sh = run(["--dry-run", str(r2)], script=SHIM)
            assert sh.returncode == 0, sh.stderr + sh.stdout
            assert "Screenshots" in sh.stdout

        # refuse home
        bad = run(["--dry-run", str(Path.home())])
        assert bad.returncode != 0

        # extension mode
        with tempfile.TemporaryDirectory(prefix="tcu-ext-") as td3:
            r3 = Path(td3)
            (r3 / "a.PDF").write_bytes(b"p")
            (r3 / "b.txt").write_bytes(b"t")
            e = run(["--by", "extension", str(r3)])
            assert e.returncode == 0, e.stderr
            assert (r3 / "pdf" / "a.PDF").exists()
            assert (r3 / "txt" / "b.txt").exists()

    print("test_fs_smart_organize: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
