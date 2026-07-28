#!/usr/bin/env python3
"""Unit tests for browser_policy (no Playwright required)."""
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "skills" / "computer" / "scripts" / "lib"
sys.path.insert(0, str(LIB))

import browser_policy as policy  # noqa: E402


class HostAllowlist(unittest.TestCase):
    def test_empty_allowlist_allows_all(self):
        self.assertTrue(policy.host_allowed("https://medium.com/x", []))

    def test_exact_and_subdomain(self):
        allow = ["medium.com"]
        self.assertTrue(policy.host_allowed("https://medium.com/new-story", allow))
        self.assertTrue(policy.host_allowed("https://www.medium.com/", allow))
        self.assertFalse(policy.host_allowed("https://evil.com/", allow))

    def test_wildcard_suffix(self):
        allow = ["*.medium.com"]
        self.assertTrue(policy.host_allowed("https://cdn.medium.com/a", allow))
        self.assertTrue(policy.host_allowed("https://medium.com/a", allow))


class SafeMode(unittest.TestCase):
    def setUp(self):
        self._old = os.environ.get("TCU_SAFE_MODE")
        os.environ["TCU_SAFE_MODE"] = "1"

    def tearDown(self):
        if self._old is None:
            os.environ.pop("TCU_SAFE_MODE", None)
        else:
            os.environ["TCU_SAFE_MODE"] = self._old

    def test_blocks_click(self):
        ok, msg = policy.check_action("click", flags=[])
        self.assertFalse(ok)
        self.assertIn("SAFE_MODE", msg)

    def test_allows_status(self):
        ok, msg = policy.check_action("status", flags=[])
        self.assertTrue(ok)


class PublishGate(unittest.TestCase):
    def setUp(self):
        os.environ.pop("TCU_SAFE_MODE", None)

    def test_publish_click_needs_flag(self):
        ok, msg = policy.check_action("publish-click", flags=[])
        self.assertFalse(ok)
        self.assertIn("--i-mean-it", msg)

    def test_publish_click_with_flag(self):
        ok, msg = policy.check_action("publish-click", flags=["--i-mean-it"])
        self.assertTrue(ok, msg)

    def test_medium_publish_needs_flag(self):
        ok, msg = policy.check_action("medium-publish", flags=[])
        self.assertFalse(ok)

    def test_click_on_publish_url_needs_flag(self):
        ok, msg = policy.check_action(
            "click", url="https://example.com/checkout", flags=[]
        )
        self.assertFalse(ok)
        self.assertIn("--i-mean-it", msg)

    def test_click_on_medium_editor_ok_without_flag(self):
        # /new-story is draft editor, not publish
        ok, msg = policy.check_action(
            "click", url="https://medium.com/new-story", flags=[]
        )
        self.assertTrue(ok, msg)

    def test_click_on_normal_url_ok(self):
        ok, msg = policy.check_action(
            "click", url="https://example.com/about", flags=[]
        )
        self.assertTrue(ok, msg)


class OpenAllowlist(unittest.TestCase):
    def test_open_blocked_host(self):
        ok, msg = policy.check_action(
            "open",
            url="https://evil.example/",
            allowlist=["medium.com"],
        )
        self.assertFalse(ok)
        self.assertIn("ALLOWLIST", msg)

    def test_open_allowed_host(self):
        ok, msg = policy.check_action(
            "open",
            url="https://medium.com/new-story",
            allowlist=["medium.com"],
        )
        self.assertTrue(ok, msg)


if __name__ == "__main__":
    unittest.main()
