#!/usr/bin/env python3
"""Unit tests for fs-organize.py (smart + extension + plan/apply/undo)."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "computer" / "scripts" / "fs-organize.py"
SHIM = ROOT / "skills" / "computer" / "scripts" / "fs-smart-organize.py"


def run(
    args: list[str],
    script: Path = SCRIPT,
    env: dict[str, str] | None = None,
    state_dir: Path | None = None,
) -> subprocess.CompletedProcess[str]:
    run_env = os.environ.copy()
    # Avoid writing plans into the real ~/.tcu during tests
    if state_dir is not None:
        run_env["TCU_STATE_DIR"] = str(state_dir)
    elif "TCU_STATE_DIR" not in (env or {}):
        run_env.setdefault("TCU_STATE_DIR", str(Path(tempfile.gettempdir()) / "tcu-test-state-default"))
    if env:
        run_env.update(env)
    return subprocess.run(
        [sys.executable, str(script), *args],
        capture_output=True,
        text=True,
        check=False,
        env=run_env,
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="tcu-test-") as td:
        root = Path(td)
        state = root / "state"
        state.mkdir()
        env_state = {"TCU_STATE_DIR": str(state)}

        (root / "Screenshot 2026-01-01 at 12.00.00 AM.png").write_bytes(b"png")
        (root / "receipt.jpg").write_bytes(b"jpg")
        (root / "notes.pdf").write_bytes(b"pdf")
        (root / "archive.zip").write_bytes(b"zip")
        (root / ".hidden").write_bytes(b"x")
        (root / ".localized").write_bytes(b"")

        dry = run(["--dry-run", "--by", "smart", str(root)], env=env_state)
        assert dry.returncode == 0, dry.stderr + dry.stdout
        assert "Screenshots" in dry.stdout
        assert "Images" in dry.stdout
        assert (root / "receipt.jpg").exists(), "dry-run must not move"
        plan_path = state / "last-organize-plan.json"
        assert plan_path.is_file(), "dry-run must write plan"
        plan = json.loads(plan_path.read_text())
        assert plan["status"] == "planned"
        assert len(plan["moves"]) >= 3

        exe = run(["--by", "smart", str(root)], env=env_state)
        assert exe.returncode == 0, exe.stderr + exe.stdout
        assert (root / "Screenshots" / "Screenshot 2026-01-01 at 12.00.00 AM.png").exists()
        assert (root / "Images" / "receipt.jpg").exists()
        assert (root / "Documents" / "notes.pdf").exists()
        assert (root / "Archives" / "archive.zip").exists()
        assert (root / ".localized").exists()
        plan = json.loads(plan_path.read_text())
        assert plan["status"] == "applied"

        # undo restores
        und = run(["--undo"], env=env_state)
        assert und.returncode == 0, und.stderr + und.stdout
        assert (root / "receipt.jpg").exists()
        assert not (root / "Images" / "receipt.jpg").exists()
        plan = json.loads(plan_path.read_text())
        assert plan["status"] == "undone"

        # re-execute for later tests isolation
        # (files are flat again)

        # shim
        with tempfile.TemporaryDirectory(prefix="tcu-shim-") as td2:
            r2 = Path(td2)
            st2 = r2 / "state"
            st2.mkdir()
            (r2 / "Screenshot x.png").write_bytes(b"p")
            sh = run(
                ["--dry-run", str(r2)],
                script=SHIM,
                env={"TCU_STATE_DIR": str(st2)},
            )
            assert sh.returncode == 0, sh.stderr + sh.stdout
            assert "Screenshots" in sh.stdout

        # refuse home
        bad = run(["--dry-run", str(Path.home())], env=env_state)
        assert bad.returncode != 0

        # extension mode
        with tempfile.TemporaryDirectory(prefix="tcu-ext-") as td3:
            r3 = Path(td3)
            st3 = r3 / "state"
            st3.mkdir()
            (r3 / "a.PDF").write_bytes(b"p")
            (r3 / "b.txt").write_bytes(b"t")
            e = run(
                ["--by", "extension", str(r3)],
                env={"TCU_STATE_DIR": str(st3)},
            )
            assert e.returncode == 0, e.stderr
            assert (r3 / "pdf" / "a.PDF").exists()
            assert (r3 / "txt" / "b.txt").exists()

        # TCU_SAFE_MODE forces dry-run (no moves)
        with tempfile.TemporaryDirectory(prefix="tcu-safe-") as td4:
            r4 = Path(td4)
            st4 = r4 / "state"
            st4.mkdir()
            (r4 / "keep-me.jpg").write_bytes(b"jpg")
            safe = run(
                ["--by", "smart", str(r4)],
                env={"TCU_SAFE_MODE": "1", "TCU_STATE_DIR": str(st4)},
            )
            assert safe.returncode == 0, safe.stderr + safe.stdout
            assert "forcing dry-run" in (safe.stderr + safe.stdout)
            assert "DRY-RUN" in safe.stdout
            assert (r4 / "keep-me.jpg").exists(), "SAFE_MODE must not move"
            assert not (r4 / "Images" / "keep-me.jpg").exists()

        # plan → apply
        with tempfile.TemporaryDirectory(prefix="tcu-apply-") as td5:
            r5 = Path(td5)
            st5 = r5 / "state"
            st5.mkdir()
            (r5 / "photo.png").write_bytes(b"png")
            e_state = {"TCU_STATE_DIR": str(st5)}
            d = run(["--dry-run", "--by", "smart", str(r5)], env=e_state)
            assert d.returncode == 0, d.stderr + d.stdout
            assert (r5 / "photo.png").exists()
            a = run(["--apply"], env=e_state)
            assert a.returncode == 0, a.stderr + a.stdout
            assert (r5 / "Images" / "photo.png").exists()
            assert not (r5 / "photo.png").exists()

        # SAFE_MODE blocks apply and undo
        with tempfile.TemporaryDirectory(prefix="tcu-block-") as td6:
            r6 = Path(td6)
            st6 = r6 / "state"
            st6.mkdir()
            (r6 / "x.jpg").write_bytes(b"j")
            e_state = {"TCU_STATE_DIR": str(st6)}
            assert run(["--by", "smart", str(r6)], env=e_state).returncode == 0
            blocked_apply = run(
                ["--apply"],
                env={**e_state, "TCU_SAFE_MODE": "1"},
            )
            assert blocked_apply.returncode != 0
            assert "SAFE_MODE" in (blocked_apply.stderr + blocked_apply.stdout)
            blocked_undo = run(
                ["--undo"],
                env={**e_state, "TCU_SAFE_MODE": "1"},
            )
            assert blocked_undo.returncode != 0

        # undo fails cleanly if dest deleted
        with tempfile.TemporaryDirectory(prefix="tcu-badundo-") as td7:
            r7 = Path(td7)
            st7 = r7 / "state"
            st7.mkdir()
            (r7 / "gone.jpg").write_bytes(b"j")
            e_state = {"TCU_STATE_DIR": str(st7)}
            assert run(["--by", "smart", str(r7)], env=e_state).returncode == 0
            moved = r7 / "Images" / "gone.jpg"
            assert moved.is_file()
            moved.unlink()
            u = run(["--undo"], env=e_state)
            assert u.returncode != 0, "undo should fail when dest missing"

    print("test_fs_smart_organize: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
