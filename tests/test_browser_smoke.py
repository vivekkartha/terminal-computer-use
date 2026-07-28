#!/usr/bin/env python3
"""Live Playwright smoke: data-URL page click/fill. Skips if playwright/chromium missing."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BROWSER_SH = ROOT / "skills" / "computer" / "scripts" / "browser.sh"
BROWSER_PY = ROOT / "skills" / "computer" / "scripts" / "lib" / "browser.py"


def has_playwright() -> bool:
    try:
        import playwright  # noqa: F401
    except ImportError:
        return False
    return True


def run_browser(*args: str, env=None, timeout=60) -> subprocess.CompletedProcess:
    e = os.environ.copy()
    if env:
        e.update(env)
    return subprocess.run(
        [sys.executable, str(BROWSER_PY), *args],
        capture_output=True,
        text=True,
        env=e,
        timeout=timeout,
    )


@unittest.skipUnless(has_playwright(), "playwright not installed")
class BrowserSmoke(unittest.TestCase):
    def setUp(self):
        self.td = tempfile.mkdtemp(prefix="tcu-browser-")
        self.state = Path(self.td) / "state"
        self.state.mkdir()
        self.env = {
            "TCU_STATE_DIR": str(self.state),
            "TCU_SAFE_MODE": "0",
        }
        # stop any leftover from this state dir
        run_browser("stop", env=self.env)

    def tearDown(self):
        run_browser("stop", env=self.env)
        shutil.rmtree(self.td, ignore_errors=True)

    def test_help(self):
        r = run_browser("--help", env=self.env)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("medium-draft", r.stdout + r.stderr)

    def test_start_open_click_fill_stop(self):
        r = run_browser("start", "--headless", env=self.env, timeout=90)
        if r.returncode != 0:
            self.skipTest(f"browser start failed (chromium?): {r.stderr}")
        try:
            data = json.loads(r.stdout.strip().splitlines()[-1])
            self.assertTrue(data.get("ok"))

            # data URL with button + input
            html = (
                "data:text/html,"
                "<html><body>"
                '<input id="t" value=""/>'
                '<button id="b">Go</button>'
                '<div id="out"></div>'
                "<script>"
                'document.getElementById("b").onclick=()=>{'
                'document.getElementById("out").textContent='
                'document.getElementById("t").value;};'
                "</script></body></html>"
            )
            r2 = run_browser("open", html, env=self.env, timeout=60)
            self.assertEqual(r2.returncode, 0, r2.stderr + r2.stdout)

            r3 = run_browser("fill", "#t", "hello-tcu", env=self.env)
            self.assertEqual(r3.returncode, 0, r3.stderr)

            r4 = run_browser("click", "#b", env=self.env)
            self.assertEqual(r4.returncode, 0, r4.stderr)

            r5 = run_browser("text", "#out", env=self.env)
            self.assertEqual(r5.returncode, 0, r5.stderr)
            self.assertIn("hello-tcu", r5.stdout)
        finally:
            run_browser("stop", env=self.env)

    def test_publish_blocked_without_flag(self):
        r = run_browser("publish-click", "button", env=self.env)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("i-mean-it", (r.stderr + r.stdout).lower())

    def test_safe_mode_blocks_click(self):
        e = dict(self.env, TCU_SAFE_MODE="1")
        # start not needed — policy fails first for click without session after policy
        r = run_browser("click", "#x", env=e)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("SAFE_MODE", r.stderr + r.stdout)


class BrowserShHelp(unittest.TestCase):
    def test_browser_sh_help(self):
        r = subprocess.run(
            ["bash", str(BROWSER_SH), "--help"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        out = r.stdout + r.stderr
        self.assertIn("medium-publish", out)
        self.assertIn("start", out)


if __name__ == "__main__":
    unittest.main()
