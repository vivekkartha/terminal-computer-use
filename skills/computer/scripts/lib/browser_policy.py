#!/usr/bin/env python3
"""Browser control policy for Terminal Computer Use (no Playwright dependency)."""
from __future__ import annotations

import os
import re
from typing import Iterable, List, Optional, Sequence, Tuple
from urllib.parse import urlparse

# Actions that mutate page / account state
MUTATING_ACTIONS = frozenset(
    {
        "click",
        "fill",
        "type",
        "press",
        "select",
        "paste",
        "publish-click",
        "medium-draft",
        "medium-publish",
    }
)

# Read-only / session lifecycle (allowed under SAFE_MODE)
SAFE_ACTIONS = frozenset(
    {
        "start",
        "stop",
        "status",
        "open",
        "url",
        "title",
        "text",
        "html",
        "screenshot",
        "copy",
        "wait",
        "help",
    }
)

# Explicit publish / external-send style actions require --i-mean-it
PUBLISH_ACTIONS = frozenset({"publish-click", "medium-publish"})

# Path/query hints that look like a final submit/publish step (not editor URLs).
# Note: Medium /new-story is the editor — do NOT treat as publish.
PUBLISH_URL_HINTS = re.compile(
    r"(publish|checkout|confirm-order|/submit\b)",
    re.I,
)


def env_truthy(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default).strip().lower() in {
        "1",
        "true",
        "yes",
        "y",
        "on",
    }


def safe_mode() -> bool:
    return env_truthy("TCU_SAFE_MODE", "0")


def parse_allowlist(raw: Optional[str] = None) -> List[str]:
    """Comma-separated domain allowlist. Empty = allow all hosts."""
    if raw is None:
        raw = os.environ.get("TCU_BROWSER_ALLOWLIST", "")
    parts = [p.strip().lower() for p in raw.split(",") if p.strip()]
    return parts


def host_of(url: str) -> str:
    u = urlparse(url if "://" in url else f"https://{url}")
    return (u.hostname or "").lower()


def host_allowed(url: str, allowlist: Optional[Sequence[str]] = None) -> bool:
    allow = list(allowlist) if allowlist is not None else parse_allowlist()
    if not allow:
        return True
    host = host_of(url)
    if not host:
        return False
    for rule in allow:
        rule = rule.lower().lstrip(".")
        if rule.startswith("*."):
            suffix = rule[2:]
            if host == suffix or host.endswith("." + suffix):
                return True
        elif host == rule or host.endswith("." + rule):
            return True
    return False


def looks_like_publish_url(url: str) -> bool:
    return bool(PUBLISH_URL_HINTS.search(url or ""))


def require_i_mean_it(action: str, flags: Iterable[str], url: str = "") -> Optional[str]:
    """
    Return error message if action is blocked without --i-mean-it; else None.
    """
    flags_set = set(flags)
    if action in PUBLISH_ACTIONS and "--i-mean-it" not in flags_set:
        return (
            f"{action} requires --i-mean-it (explicit publish intent). "
            "Refusing silent publish."
        )
    if action == "click" and looks_like_publish_url(url) and "--i-mean-it" not in flags_set:
        return (
            "click on a publish-like URL requires --i-mean-it. "
            "Refusing silent publish navigation."
        )
    return None


def check_action(
    action: str,
    *,
    url: str = "",
    flags: Optional[Sequence[str]] = None,
    allowlist: Optional[Sequence[str]] = None,
) -> Tuple[bool, str]:
    """
    Policy gate for one browser command.
    Returns (ok, message). message is error text when ok is False.
    """
    flags = list(flags or [])
    action = action.strip().lower()

    if action in ("-h", "--help", "help"):
        return True, ""

    if safe_mode() and action in MUTATING_ACTIONS:
        return False, f"TCU_SAFE_MODE=1 blocks mutating browser action: {action}"

    if action == "open" or action.startswith("medium"):
        if url and not host_allowed(url, allowlist):
            return (
                False,
                f"url host not in TCU_BROWSER_ALLOWLIST: {host_of(url) or url}",
            )

    if action == "open" and url and not host_allowed(url, allowlist):
        return False, f"url host not in TCU_BROWSER_ALLOWLIST: {host_of(url) or url}"

    err = require_i_mean_it(action, flags, url=url)
    if err:
        return False, err

    return True, ""


def state_dir() -> str:
    base = os.environ.get("TCU_STATE_DIR") or os.path.join(
        os.path.expanduser("~"), ".tcu"
    )
    return os.path.join(base, "browser")
