# Changelog

## [Unreleased]

### Added
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
