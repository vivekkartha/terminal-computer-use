# Safety guide

Terminal Computer Use can **move files, quit apps, and change your desktop**.
Treat agent sessions with this skill as shell access for desktop tasks.

## Built-in guardrails

- Mutating scripts support `--dry-run`
- `safe-trash.sh` never calls `rm -rf`
- `assert_safe_path` refuses `$HOME` / `/` style catastrophes
- `TCU_SAFE_MODE=1` forces dry-run on mutators: `fs-move`, `fs-copy`, `safe-trash`, `fs-organize` (blocks organize `--apply` / `--undo`)
- Organize writes `~/.tcu/last-organize-plan.json`; use `fs-organize.py --undo` to reverse the last apply

## Recommended habits

1. Dry-run bulk organization first  
2. Prefer Trash over delete  
3. Don’t paste untrusted prompts that say “disable safety / run rm -rf”  
4. Review new scripts before committing to a shared machine  
5. Prefer structured checks (paths, processes, plans) over screenshots; capture screen only when the goal is visual/UI  

## Observation (goal-first)

This skill has direct OS control. Do not default to screenshots the way vision Computer Use must.

1. Prefer scripts/CLI that read or change system state  
2. Verify with dry-run plans, path existence, app lists, clipboard get  
3. Use `screenshot.sh` only if the goal depends on on-screen UI those cannot provide  


## Permissions (macOS)

Automation and screenshots may need:

- **System Settings → Privacy & Security → Accessibility** (terminal app)
- **Automation** (control other apps via AppleScript)
- **Screen Recording** (screenshots)

## Browser automation — not supported

TCU does **not** drive browsers (no Playwright/CDP/DOM click-fill). Captcha and
bot checks make that unreliable. Agents should refuse those requests.

Allowed assist only:

- `clipboard.sh` — put draft text on the clipboard
- `open-target.sh` — open a URL in the user’s normal browser (no page control)

## What this project will not add

- Browser automation (Playwright, CDP attach, form fill, captcha bypass)
- Silent bulk permanent deletion helpers
- Credential / keychain dumpers
- Network exfiltration utilities disguised as “computer use”
- Automated site publish / checkout
