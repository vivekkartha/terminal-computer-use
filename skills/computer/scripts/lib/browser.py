#!/usr/bin/env python3
"""
TCU browser control — Playwright DOM (shell-first, not vision/pixel CU).

Session model:
  start → launch Chromium (persistent profile under ~/.tcu/browser/profile),
          expose CDP on a free port, write session.json
  later commands → connect_over_cdp, act on first page (or new page)
  stop → kill browser process, clear session

Optional: TCU_BROWSER_ALLOWLIST, TCU_SAFE_MODE, --i-mean-it for publish.
"""
from __future__ import annotations

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

# Allow `python3 lib/browser.py` and package-style imports
_LIB = Path(__file__).resolve().parent
if str(_LIB) not in sys.path:
    sys.path.insert(0, str(_LIB))

import browser_policy as policy  # noqa: E402


def die(msg: str, code: int = 1) -> None:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def ensure_playwright():
    try:
        from playwright.sync_api import sync_playwright  # noqa: F401
    except ImportError:
        die(
            "playwright not installed. Run:\n"
            "  python3 -m pip install playwright\n"
            "  python3 -m playwright install chromium"
        )
    return __import__("playwright.sync_api", fromlist=["sync_playwright"]).sync_playwright


def state_paths() -> Dict[str, Path]:
    root = Path(policy.state_dir())
    root.mkdir(parents=True, mode=0o700, exist_ok=True)
    return {
        "root": root,
        "session": root / "session.json",
        "profile": root / "profile",
        "pid": root / "browser.pid",
    }


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


def read_session() -> Optional[Dict[str, Any]]:
    p = state_paths()["session"]
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text())
    except (OSError, json.JSONDecodeError):
        return None


def write_session(data: Dict[str, Any]) -> None:
    p = state_paths()["session"]
    p.write_text(json.dumps(data, indent=2) + "\n")
    try:
        p.chmod(0o600)
    except OSError:
        pass


def clear_session() -> None:
    sp = state_paths()
    for key in ("session", "pid"):
        try:
            sp[key].unlink()
        except FileNotFoundError:
            pass


def port_open(port: int) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.4):
            return True
    except OSError:
        return False


def cmd_connect(args: argparse.Namespace) -> int:
    """Attach to an existing browser CDP (real Chrome — captcha-friendly)."""
    port = int(args.port)
    if not port_open(port):
        die(
            f"nothing listening on 127.0.0.1:{port}. Start real Chrome first:\n"
            f'  bash "$(dirname "$0")/../chrome-cdp.sh"   # or see references/browser.md'
        )
    cdp = f"http://127.0.0.1:{port}"
    # verify CDP speaks
    try:
        import urllib.request

        with urllib.request.urlopen(f"{cdp}/json/version", timeout=3) as r:
            meta = json.loads(r.read().decode())
    except Exception as e:
        die(f"CDP port open but not Chrome DevTools: {e}")

    sess = {
        "port": port,
        "cdp": cdp,
        "pid": None,  # external process — stop will not kill Chrome
        "profile": "external-cdp",
        "headed": True,
        "channel": "external",
        "browser": meta.get("Browser", "unknown"),
        "external": True,
    }
    write_session(sess)
    # no pid file ownership
    try:
        state_paths()["pid"].unlink()
    except FileNotFoundError:
        pass
    print(json.dumps({"ok": True, "already_running": True, **sess}))
    return 0


def cmd_start(args: argparse.Namespace) -> int:
    # Attach-only path (preferred for Medium / Cloudflare sites)
    if getattr(args, "connect_port", None):
        args.port = args.connect_port
        return cmd_connect(args)

    existing = read_session()
    if existing and port_open(int(existing.get("port", 0))):
        print(json.dumps({"ok": True, "already_running": True, **existing}))
        return 0

    port = free_port()
    profile = Path(args.profile) if args.profile else state_paths()["profile"]
    profile.mkdir(parents=True, mode=0o700, exist_ok=True)

    # Launch via Playwright Python so Chromium path is correct.
    # Use a small detached helper process that holds the browser open.
    # NOTE: Playwright Chromium is often blocked by Cloudflare captchas.
    # For Medium auth, prefer: chrome-cdp.sh + browser.sh connect --port 9222
    helper = Path(__file__).resolve().parent / "browser_daemon.py"
    env = os.environ.copy()
    env["TCU_BROWSER_PORT"] = str(port)
    env["TCU_BROWSER_PROFILE"] = str(profile)
    env["TCU_BROWSER_HEADED"] = "0" if args.headless else "1"
    env["TCU_BROWSER_CHANNEL"] = args.channel or ""

    proc = subprocess.Popen(
        [sys.executable, str(helper)],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )

    # Wait for CDP
    deadline = time.time() + 30
    while time.time() < deadline:
        if port_open(port):
            break
        if proc.poll() is not None:
            die("browser daemon exited early — is chromium installed? "
                "python3 -m playwright install chromium")
        time.sleep(0.15)
    else:
        try:
            os.kill(proc.pid, signal.SIGTERM)
        except OSError:
            pass
        die("timeout waiting for browser CDP port")

    sess = {
        "port": port,
        "cdp": f"http://127.0.0.1:{port}",
        "pid": proc.pid,
        "profile": str(profile),
        "headed": not args.headless,
        "channel": args.channel or "chromium",
        "external": False,
    }
    write_session(sess)
    state_paths()["pid"].write_text(str(proc.pid) + "\n")
    print(json.dumps({"ok": True, "already_running": False, **sess}))
    return 0


def cmd_stop(_args: argparse.Namespace) -> int:
    sess = read_session()
    if sess and sess.get("external"):
        # Do not kill user's real Chrome — only drop session binding
        clear_session()
        print(json.dumps({"ok": True, "stopped": True, "note": "detached CDP only; Chrome left running"}))
        return 0
    pid = None
    if sess:
        pid = sess.get("pid")
    pid_file = state_paths()["pid"]
    if pid is None and pid_file.is_file():
        try:
            pid = int(pid_file.read_text().strip())
        except ValueError:
            pid = None
    if pid:
        try:
            os.kill(int(pid), signal.SIGTERM)
        except OSError:
            pass
        # best-effort wait
        for _ in range(20):
            try:
                os.kill(int(pid), 0)
                time.sleep(0.1)
            except OSError:
                break
        else:
            try:
                os.kill(int(pid), signal.SIGKILL)
            except OSError:
                pass
    clear_session()
    print(json.dumps({"ok": True, "stopped": True}))
    return 0


def connect_page():
    sync_playwright = ensure_playwright()
    sess = read_session()
    if not sess or not port_open(int(sess.get("port", 0))):
        die("no browser session — run: browser.sh start [--headed]")
    cdp = sess["cdp"]
    pw = sync_playwright().start()
    browser = pw.chromium.connect_over_cdp(cdp)
    if not browser.contexts:
        die("browser connected but no contexts")
    ctx = browser.contexts[0]
    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    return pw, browser, page


def with_page(fn):
    pw, browser, page = connect_page()
    try:
        return fn(page)
    finally:
        try:
            browser.close()
        except Exception:
            pass
        try:
            pw.stop()
        except Exception:
            pass


def cmd_status(_args: argparse.Namespace) -> int:
    sess = read_session()
    if not sess or not port_open(int(sess.get("port", 0))):
        print(json.dumps({"ok": True, "running": False}))
        return 0

    def _info(page):
        return {
            "ok": True,
            "running": True,
            "url": page.url,
            "title": page.title(),
            "port": sess.get("port"),
            "profile": sess.get("profile"),
        }

    print(json.dumps(with_page(_info)))
    return 0


def cmd_open(args: argparse.Namespace) -> int:
    url = args.url
    ok, msg = policy.check_action("open", url=url, flags=args.flags)
    if not ok:
        die(msg)

    def _open(page):
        page.goto(url, wait_until="domcontentloaded", timeout=args.timeout)
        return {"ok": True, "url": page.url, "title": page.title()}

    print(json.dumps(with_page(_open)))
    return 0


def cmd_url(_args: argparse.Namespace) -> int:
    print(with_page(lambda p: p.url))
    return 0


def cmd_title(_args: argparse.Namespace) -> int:
    print(with_page(lambda p: p.title()))
    return 0


def cmd_text(args: argparse.Namespace) -> int:
    def _t(page):
        loc = page.locator(args.selector).first
        loc.wait_for(state="attached", timeout=args.timeout)
        return loc.inner_text(timeout=args.timeout)

    print(with_page(_t))
    return 0


def cmd_html(args: argparse.Namespace) -> int:
    def _h(page):
        loc = page.locator(args.selector).first
        loc.wait_for(state="attached", timeout=args.timeout)
        return loc.inner_html(timeout=args.timeout)

    print(with_page(_h))
    return 0


def cmd_screenshot(args: argparse.Namespace) -> int:
    out = Path(args.out or str(state_paths()["root"] / "page.png"))
    out.parent.mkdir(parents=True, exist_ok=True)

    def _s(page):
        page.screenshot(path=str(out), full_page=bool(args.full_page))
        return {"ok": True, "path": str(out.resolve())}

    print(json.dumps(with_page(_s)))
    return 0


def cmd_click(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action(
        "click", url=getattr(args, "page_url", "") or "", flags=args.flags
    )
    # Also check live page URL for publish-like paths when possible
    if not ok:
        die(msg)

    def _c(page):
        live = page.url
        ok2, msg2 = policy.check_action("click", url=live, flags=args.flags)
        if not ok2:
            die(msg2)
        loc = page.locator(args.selector).first
        loc.click(timeout=args.timeout)
        return {"ok": True, "clicked": args.selector, "url": page.url}

    print(json.dumps(with_page(_c)))
    return 0


def cmd_fill(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("fill", flags=args.flags)
    if not ok:
        die(msg)
    text = args.text
    if args.file:
        text = Path(args.file).expanduser().read_text()

    def _f(page):
        loc = page.locator(args.selector).first
        loc.fill(text, timeout=args.timeout)
        return {"ok": True, "filled": args.selector, "chars": len(text)}

    print(json.dumps(with_page(_f)))
    return 0


def cmd_type(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("type", flags=args.flags)
    if not ok:
        die(msg)
    text = args.text
    if args.file:
        text = Path(args.file).expanduser().read_text()

    def _t(page):
        loc = page.locator(args.selector).first
        loc.click(timeout=args.timeout)
        page.keyboard.type(text, delay=args.delay)
        return {"ok": True, "typed": args.selector, "chars": len(text)}

    print(json.dumps(with_page(_t)))
    return 0


def cmd_press(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("press", flags=args.flags)
    if not ok:
        die(msg)

    def _p(page):
        if args.selector:
            page.locator(args.selector).first.press(args.key, timeout=args.timeout)
        else:
            page.keyboard.press(args.key)
        return {"ok": True, "key": args.key}

    print(json.dumps(with_page(_p)))
    return 0


def cmd_wait(args: argparse.Namespace) -> int:
    def _w(page):
        page.locator(args.selector).first.wait_for(
            state=args.state, timeout=args.timeout
        )
        return {"ok": True, "selector": args.selector, "state": args.state}

    print(json.dumps(with_page(_w)))
    return 0


def cmd_copy(args: argparse.Namespace) -> int:
    """Copy selector text to stdout (caller/shell may pipe to clipboard.sh)."""

    def _c(page):
        loc = page.locator(args.selector).first
        loc.wait_for(state="attached", timeout=args.timeout)
        return loc.inner_text(timeout=args.timeout)

    print(with_page(_c), end="")
    return 0


def cmd_paste(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("paste", flags=args.flags)
    if not ok:
        die(msg)
    # stdin or --file
    if args.file:
        text = Path(args.file).expanduser().read_text()
    elif not sys.stdin.isatty():
        text = sys.stdin.read()
    else:
        die("paste needs --file or stdin text")

    def _p(page):
        loc = page.locator(args.selector).first
        loc.click(timeout=args.timeout)
        # Prefer fill for inputs; type for contenteditable
        try:
            loc.fill(text, timeout=args.timeout)
        except Exception:
            page.keyboard.insert_text(text)
        return {"ok": True, "pasted": args.selector, "chars": len(text)}

    print(json.dumps(with_page(_p)))
    return 0


def cmd_publish_click(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("publish-click", flags=args.flags)
    if not ok:
        die(msg)

    def _p(page):
        loc = page.locator(args.selector).first
        loc.click(timeout=args.timeout)
        page.wait_for_timeout(500)
        return {"ok": True, "published_click": args.selector, "url": page.url}

    print(json.dumps(with_page(_p)))
    return 0


# --- Medium helpers (selectors are best-effort; Medium DOM drifts) ---

MEDIUM_TITLE_SEL = (
    'h1[data-testid="editorTitleParagraph"], '
    'h1[contenteditable="true"], '
    '[data-testid="editor-title"], '
    'textarea[placeholder*="Title"], '
    'h1.graf--title'
)
MEDIUM_BODY_SEL = (
    'div[data-testid="editorParagraphText"], '
    '.ProseMirror, '
    'div[contenteditable="true"][role="textbox"], '
    'div.section-content div[contenteditable="true"]'
)
MEDIUM_PUBLISH_SEL = (
    'button:has-text("Publish"), '
    'button[data-action="publish"], '
    'button[data-testid="publishButton"], '
    '[data-testid="publish-button"]'
)
MEDIUM_CONFIRM_SEL = (
    'button:has-text("Publish now"), '
    'button:has-text("Publish to"), '
    'button[data-action="publish-confirm"]'
)


def cmd_medium_draft(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action(
        "medium-draft",
        url=args.url or "https://medium.com/new-story",
        flags=args.flags,
    )
    if not ok:
        die(msg)

    title = args.title or ""
    body = ""
    if args.body_file:
        body = Path(args.body_file).expanduser().read_text()
    elif args.body:
        body = args.body

    url = args.url or "https://medium.com/new-story"

    def _draft(page):
        page.goto(url, wait_until="domcontentloaded", timeout=args.timeout)
        page.wait_for_timeout(1500)
        live = page.url or ""
        title = (page.title() or "").lower()
        if "just a moment" in title or "cf-chl" in live or "challenge" in live:
            shot = state_paths()["root"] / "medium-draft.png"
            page.screenshot(path=str(shot), full_page=False)
            die(
                "Cloudflare captcha wall — Playwright Chromium cannot pass this. "
                "Use real Chrome: bash …/chrome-cdp.sh  →  browser.sh connect --port 9222. "
                f"url={live} screenshot={shot}"
            )
        if "signin" in live or "login" in live.lower() or "/m/signin" in live:
            shot = state_paths()["root"] / "medium-draft.png"
            page.screenshot(path=str(shot), full_page=False)
            die(
                "Medium login required (landed on sign-in). "
                "Playwright Chromium often fails captcha. Prefer real Chrome CDP:\n"
                "  bash \"$SCRIPTS/chrome-cdp.sh\"   # complete captcha+login once\n"
                "  bash \"$SCRIPTS/browser.sh\" connect --port 9222\n"
                f"url={live} screenshot={shot}"
            )
        # Title
        if title:
            tloc = page.locator(MEDIUM_TITLE_SEL).first
            try:
                tloc.click(timeout=8000)
                try:
                    tloc.fill(title, timeout=3000)
                except Exception:
                    page.keyboard.insert_text(title)
            except Exception as e:
                log(f"warn: title fill failed ({e}); try manual title")
        # Body — focus largest contenteditable
        if body:
            try:
                bloc = page.locator(MEDIUM_BODY_SEL).first
                bloc.click(timeout=8000)
                page.keyboard.insert_text(body)
            except Exception as e:
                log(f"warn: body insert failed ({e})")
                # fallback: clipboard-like insert via evaluate
                page.evaluate(
                    """(text) => {
                      const el = document.querySelector('[contenteditable="true"]');
                      if (el) { el.focus(); document.execCommand('insertText', false, text); }
                    }""",
                    body,
                )
        shot = state_paths()["root"] / "medium-draft.png"
        page.screenshot(path=str(shot), full_page=False)
        return {
            "ok": True,
            "url": page.url,
            "title_chars": len(title),
            "body_chars": len(body),
            "screenshot": str(shot),
            "next": "Review headed browser. Publish only with: "
            "browser.sh medium-publish --i-mean-it",
        }

    print(json.dumps(with_page(_draft)))
    return 0


def cmd_medium_publish(args: argparse.Namespace) -> int:
    ok, msg = policy.check_action("medium-publish", flags=args.flags)
    if not ok:
        die(msg)

    def _pub(page):
        live = page.url or ""
        if "signin" in live or "/m/signin" in live:
            die(f"Medium login required before publish (url={live})")
        # First Publish button (opens modal)
        try:
            page.locator(MEDIUM_PUBLISH_SEL).first.click(timeout=args.timeout)
            page.wait_for_timeout(800)
        except Exception as e:
            die(f"could not click Publish control: {e}")
        # Confirm if present
        try:
            conf = page.locator(MEDIUM_CONFIRM_SEL).first
            if conf.count() >= 0:
                conf.click(timeout=5000)
        except Exception:
            log("warn: no secondary publish confirm — first click may be enough")
        page.wait_for_timeout(1000)
        return {"ok": True, "url": page.url, "note": "publish click issued"}

    print(json.dumps(with_page(_pub)))
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="browser.py",
        description="TCU Playwright browser control (DOM, not vision CU)",
    )
    p.add_argument(
        "--i-mean-it",
        action="store_true",
        help="required for publish-click / medium-publish",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("start", help="start browser session")
    s.add_argument("--headed", action="store_true", help="show browser UI (default)")
    s.add_argument("--headless", action="store_true", help="headless chromium")
    s.add_argument("--profile", default="", help="user data dir (default ~/.tcu/browser/profile)")
    s.add_argument("--channel", default="", help="chrome|chromium|msedge (optional)")
    s.add_argument(
        "--connect-port",
        type=int,
        default=0,
        help="attach to existing Chrome CDP port (no launch; captcha-friendly)",
    )
    s.set_defaults(func=cmd_start)

    c = sub.add_parser(
        "connect",
        help="attach to real Chrome CDP (use after chrome-cdp.sh; bypasses bot Chromium captcha)",
    )
    c.add_argument("--port", type=int, default=9222)
    c.set_defaults(func=cmd_connect)

    sub.add_parser("stop", help="stop browser session").set_defaults(func=cmd_stop)
    sub.add_parser("status", help="session + page status JSON").set_defaults(
        func=cmd_status
    )

    o = sub.add_parser("open", help="navigate to URL")
    o.add_argument("url")
    o.add_argument("--timeout", type=int, default=30000)
    o.set_defaults(func=cmd_open)

    sub.add_parser("url", help="print current URL").set_defaults(func=cmd_url)
    sub.add_parser("title", help="print page title").set_defaults(func=cmd_title)

    t = sub.add_parser("text", help="inner_text of selector")
    t.add_argument("selector")
    t.add_argument("--timeout", type=int, default=15000)
    t.set_defaults(func=cmd_text)

    h = sub.add_parser("html", help="inner_html of selector")
    h.add_argument("selector")
    h.add_argument("--timeout", type=int, default=15000)
    h.set_defaults(func=cmd_html)

    sc = sub.add_parser("screenshot", help="page screenshot")
    sc.add_argument("out", nargs="?", default="")
    sc.add_argument("--full-page", action="store_true")
    sc.set_defaults(func=cmd_screenshot)

    c = sub.add_parser("click", help="click selector")
    c.add_argument("selector")
    c.add_argument("--timeout", type=int, default=15000)
    c.set_defaults(func=cmd_click)

    f = sub.add_parser("fill", help="fill input selector")
    f.add_argument("selector")
    f.add_argument("text", nargs="?", default="")
    f.add_argument("--file", default="")
    f.add_argument("--timeout", type=int, default=15000)
    f.set_defaults(func=cmd_fill)

    ty = sub.add_parser("type", help="keyboard type into selector")
    ty.add_argument("selector")
    ty.add_argument("text", nargs="?", default="")
    ty.add_argument("--file", default="")
    ty.add_argument("--delay", type=int, default=0)
    ty.add_argument("--timeout", type=int, default=15000)
    ty.set_defaults(func=cmd_type)

    pr = sub.add_parser("press", help="press key")
    pr.add_argument("key")
    pr.add_argument("--selector", default="")
    pr.add_argument("--timeout", type=int, default=15000)
    pr.set_defaults(func=cmd_press)

    w = sub.add_parser("wait", help="wait for selector")
    w.add_argument("selector")
    w.add_argument("--state", default="visible")
    w.add_argument("--timeout", type=int, default=15000)
    w.set_defaults(func=cmd_wait)

    cp = sub.add_parser("copy", help="print selector text (pipe to clipboard.sh)")
    cp.add_argument("selector")
    cp.add_argument("--timeout", type=int, default=15000)
    cp.set_defaults(func=cmd_copy)

    pa = sub.add_parser("paste", help="paste file/stdin into selector")
    pa.add_argument("selector")
    pa.add_argument("--file", default="")
    pa.add_argument("--timeout", type=int, default=15000)
    pa.set_defaults(func=cmd_paste)

    pub = sub.add_parser(
        "publish-click", help="click publish control (requires --i-mean-it)"
    )
    pub.add_argument("selector")
    pub.add_argument("--timeout", type=int, default=15000)
    pub.set_defaults(func=cmd_publish_click)

    md = sub.add_parser(
        "medium-draft",
        help="open Medium new story and fill title/body (no publish)",
    )
    md.add_argument("--title", default="")
    md.add_argument("--body", default="")
    md.add_argument("--body-file", default="")
    md.add_argument("--url", default="https://medium.com/new-story")
    md.add_argument("--timeout", type=int, default=45000)
    md.set_defaults(func=cmd_medium_draft)

    mp = sub.add_parser(
        "medium-publish",
        help="click Medium Publish (requires --i-mean-it)",
    )
    mp.add_argument("--timeout", type=int, default=20000)
    mp.set_defaults(func=cmd_medium_publish)

    return p


def main(argv: Optional[List[str]] = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    # Pull global --i-mean-it before or after subcommand
    flags: List[str] = []
    if "--i-mean-it" in argv:
        flags.append("--i-mean-it")
        argv = [a for a in argv if a != "--i-mean-it"]

    parser = build_parser()
    if not argv or argv[0] in ("-h", "--help"):
        parser.print_help()
        return 0

    args = parser.parse_args(argv)
    args.flags = flags
    if getattr(args, "i_mean_it", False):
        args.flags = list(set(args.flags) | {"--i-mean-it"})

    # Default start to headed unless --headless
    if args.cmd == "start":
        if not args.headless:
            args.headed = True
        else:
            args.headed = False

    return int(args.func(args) or 0)


if __name__ == "__main__":
    raise SystemExit(main())
