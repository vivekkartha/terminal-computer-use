# Changelog

## [Unreleased]

## [0.5.0] — 2026-07-29

### Removed
- **Browser automation** (Playwright DOM): `browser.sh`, `chrome-cdp.sh`, `lib/browser*.py`, `references/browser.md`, Medium draft/publish helpers, browser demos/tests
- Rationale: captcha/bot checks and post-auth trust scoring make terminal browser control unreliable; not a TCU strength

### Changed
- Agents must **refuse** browser automation requests (click/fill/DOM/captcha/publish); optional assist: `clipboard.sh` + `open-target.sh` (open URL only)
- SKILL/README/AGENT_PROMPT/SECURITY/safety docs: desktop-only scope
- Capability surface test asserts browser scripts absent + refuse docs present
- Docs/agent prompts: professionally concise style (short summaries, tables; no walls of text)

## [0.4.0] — 2026-07-29

### Added
- **Browser DOM control** (optional Playwright): `browser.sh` + `lib/browser.py` / `browser_daemon.py` / `browser_policy.py` *(removed in 0.5.0)*
  - Session: `start` / `stop` / `status` (CDP, isolated profile under `~/.tcu/browser/`)
  - Act: `open`, `click`, `fill`, `type`, `press`, `paste`, `wait`, `text`, `html`, `screenshot`, `copy`
  - Medium: `medium-draft` (no publish) · `medium-publish --i-mean-it`
  - Gates: `TCU_SAFE_MODE`, `TCU_BROWSER_ALLOWLIST`, publish requires `--i-mean-it`
- `references/browser.md` Medium recipe + install notes
- Tests: `test_browser_policy.py`, `test_browser_smoke.py`; capability surface asserts gated publish
- `chrome-cdp.sh` + `browser.sh connect` — real Chrome CDP for Cloudflare/Medium captcha

### Changed
- SKILL/README/doctor: browser as optional capability; still not vision/pixel CU
- Capability surface test: browser present with publish gate (was “no browser.sh”)

### Added (earlier unreleased)
- GitHub Actions CI (`.github/workflows/ci.yml`) and OpenSSF Scorecard workflow

## [0.3.0] — 2026-07-23

### Added
- `fs-organize.py` plan / apply / undo: writes `~/.tcu/last-organize-plan.json`; `--apply` / `--undo`
- Design note: `docs/superpowers/specs/2026-07-23-plan-apply-undo-design.md`

### Fixed
- `fs-organize.py` honors `TCU_SAFE_MODE=1` (forces dry-run), matching move/copy/trash; SAFE_MODE blocks apply/undo
- Organize writes plan as `planned` *before* moves (crash-safer undo), single `run_moves` engine, truthful post-op receipt

### Changed
- README: new-user first-success path (install choice, doctor, agent examples, safe organize)
- Skill + agent prompt: goal-first observation — structured checks before screenshots
- Safety docs aligned: `TCU_SAFE_MODE` applies to organize and other mutators
- Organize plan JSON: drop hostname/meta noise

## [0.2.1] — 2026-07-11

### Changed
- README: shorter front page; agent prompt moved to `docs/AGENT_PROMPT.md`
- Install: clone/`./install.sh` first; skills CLI secondary
- Tone and accuracy pass (no CI claims until Actions is public)
- TRUST.md: public claims only (no maintainer TODOs)
- Agent prompt: install to `~/terminal-computer-use`, not only `/tmp`

## [0.2.0] — 2026-07-11

### Added
- `tests/smoke_release.sh` — one-command release gate
- `docs/TROUBLESHOOTING.md` — install, permissions, Linux, safety
- `VERSION` file (0.2.0)
- Installer: `--all-agents`, success/skip summary, exit 1 if nothing installed
- Doctor: version, macOS Automation hint, Linux clipboard/trash hints, try-next commands

### Changed
- README: 30s try path, support matrix, leaner structure
- SECURITY.md: explicit threat model
- CI workflow prepared for Ubuntu (publish when `workflow` scope available)

## [0.1.1] — 2026-07-11

### Fixed
- Bash 3.2 compatibility for `fs-move` / `fs-copy` (macOS `/bin/bash`)
- Paths with spaces no longer word-split
- AppleScript injection hardening via `as_escape`
- Force-quit uses exact process name only (no substring `pkill`)
- Installer refuses to clobber unmanaged skill dirs without `--force`
- `TCU_SAFE_MODE` + path guards on mutators
- Dry-run no longer creates directories as a side effect

### Changed
- Unified `fs-organize.py --by smart|extension|date` (smart shim kept)
- Shared `lib/fs.sh` for move/copy
- Platform layer owns apps + trash
- Table-driven installer; only targets existing agent homes by default

## [0.1.0] — 2026-07-11

### Added
- Initial open-source release of **Terminal Computer Use**
