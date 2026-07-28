#!/usr/bin/env python3
"""Hold a Playwright Chromium instance open for TCU browser CDP sessions."""
from __future__ import annotations

import os
import signal
import sys
import time


def main() -> int:
    port = os.environ.get("TCU_BROWSER_PORT", "").strip()
    profile = os.environ.get("TCU_BROWSER_PROFILE", "").strip()
    headed = os.environ.get("TCU_BROWSER_HEADED", "1") == "1"
    channel = os.environ.get("TCU_BROWSER_CHANNEL", "").strip() or None

    if not port or not profile:
        print("TCU_BROWSER_PORT and TCU_BROWSER_PROFILE required", file=sys.stderr)
        return 2

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("playwright missing", file=sys.stderr)
        return 2

    stop = {"go": True}

    def _stop(*_a):
        stop["go"] = False

    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)

    with sync_playwright() as p:
        launch_kwargs = {
            "user_data_dir": profile,
            "headless": not headed,
            "args": [
                f"--remote-debugging-port={port}",
                "--remote-debugging-address=127.0.0.1",
                "--no-first-run",
                "--no-default-browser-check",
            ],
        }
        if channel:
            launch_kwargs["channel"] = channel

        try:
            context = p.chromium.launch_persistent_context(**launch_kwargs)
        except Exception as e:
            # Retry without channel if channel invalid
            if channel:
                launch_kwargs.pop("channel", None)
                try:
                    context = p.chromium.launch_persistent_context(**launch_kwargs)
                except Exception as e2:
                    print(f"launch failed: {e2}", file=sys.stderr)
                    return 1
            else:
                print(f"launch failed: {e}", file=sys.stderr)
                return 1

        if not context.pages:
            context.new_page()

        while stop["go"]:
            time.sleep(0.5)

        try:
            context.close()
        except Exception:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
