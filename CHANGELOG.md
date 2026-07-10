# Changelog

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
- README redesign for discovery / conversion

## [0.1.0] — 2026-07-11

### Added
- Initial open-source release of **Terminal Computer Use**

