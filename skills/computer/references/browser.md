# Browser control (Playwright DOM)

Shell-first page control for TCU. **Not** vision/pixel computer-use.

## Install

```bash
python3 -m pip install playwright
python3 -m playwright install chromium
bash "$SCRIPTS/doctor.sh"   # WARN if missing; core file ops still OK
```

## Captcha / Medium auth (important)

Playwright **Chromium** is often blocked by Cloudflare (“Just a moment…”). It will **not** pass captcha for you.

**Do this once for Medium:**

```bash
S=…/skills/computer/scripts
bash "$S/browser.sh" stop                    # kill bot Chromium if running
bash "$S/chrome-cdp.sh"                      # real Google Chrome + port 9222
# complete captcha + Medium login in that window
bash "$S/browser.sh" connect --port 9222     # TCU attaches; does not kill Chrome
```

Session profile for that Chrome: `~/.tcu/chrome-medium` (survives restarts).

## Session

```bash
S=…/skills/computer/scripts
bash "$S/browser.sh" start --headed    # bot Chromium — OK for example.com, not Medium auth
bash "$S/browser.sh" connect --port 9222
bash "$S/browser.sh" status
bash "$S/browser.sh" stop              # bot only; on external CDP = detach only
```

## Generic DOM

```bash
bash "$S/browser.sh" open https://example.com
bash "$S/browser.sh" click 'button#submit'
bash "$S/browser.sh" fill 'input[name=q]' 'hello'
bash "$S/browser.sh" type 'div[contenteditable=true]' --file ./body.md
bash "$S/browser.sh" text 'article'
bash "$S/browser.sh" screenshot /tmp/page.png
# copy page text → system clipboard
bash "$S/browser.sh" copy 'article' | bash "$S/clipboard.sh" set
```

## Safety

| Gate | Behavior |
|------|----------|
| `TCU_SAFE_MODE=1` | Blocks click/fill/type/paste/publish |
| `TCU_BROWSER_ALLOWLIST=medium.com` | `open` / medium-* only those hosts |
| `publish-click` / `medium-publish` | Require `--i-mean-it` |
| Click while URL looks like publish path | Require `--i-mean-it` |

Network/publish = explicit user intent (same TCU safety doctrine).

## Medium recipe (human-confirm publish)

Medium’s editor DOM drifts. Treat selectors as best-effort.

```bash
# 1. Start headed so you can watch / finish login if needed
bash "$S/browser.sh" start --headed
# Optional: reuse a profile already logged into Medium
# bash "$S/browser.sh" start --headed --profile "$HOME/Library/Application Support/Google/Chrome/…"

# 2. Draft only (does NOT publish)
bash "$S/browser.sh" medium-draft \
  --title "Diagnosis-first feedback for EMs" \
  --body-file ./article.md

# 3. You review the headed window. Then, only with explicit intent:
bash "$S/browser.sh" medium-publish --i-mean-it

bash "$S/browser.sh" stop
```

If selectors break: use generic `click` / `type` after `open https://medium.com/new-story`, or fix selectors in `lib/browser.py` (`MEDIUM_*_SEL`).

## Grok / agents

Prefer `browser.sh` over screenshots for web UI goals. `open-target.sh` still opens the **user’s** normal browser (no DOM control). Do not invent pixel clicks.
