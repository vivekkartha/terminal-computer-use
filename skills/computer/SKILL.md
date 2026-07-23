---
name: computer
description: >
  Terminal-first Computer Use: control files, folders, apps, clipboard,
  notifications, screenshots, and multi-step desktop workflows via shell scripts
  (bash/Python). Works with Claude Code, Cursor, Codex, Grok, Gemini CLI, and any
  agent with a terminal. Reuse scripts next to this SKILL.md. Use when the user
  wants computer use, desktop control, open/quit apps, organize files, Finder
  automation, or runs /computer.
metadata:
  short-description: "Terminal Computer Use (shell + scripts)"
  author: vivekkartha
  version: "0.3.0"
license: MIT
compatibility: "Requires bash and python3. macOS full; Linux core (open/clipboard/notify/fs)."
---

# Terminal Computer Use

Operate the machine through the **terminal**, not GUI pixel control / vision APIs.
Prefer reusable scripts in this skill’s `scripts/` directory; write new ones when a
pattern will be reused.

## Paths (portable)

**Never hardcode `~/.grok` or any single agent’s install path.**

| Variable | Meaning |
|----------|---------|
| `SKILL_ROOT` | Directory containing this `SKILL.md` (wherever the skill was installed) |
| `SCRIPTS` | `${SKILL_ROOT}/scripts` |
| `TERMINAL_COMPUTER_USE_HOME` | Optional env override for `SKILL_ROOT` |

Resolve once per session from the loaded skill path, or:

```bash
# When running a script, paths resolve via scripts/lib/common.sh automatically.
bash "${SCRIPTS}/doctor.sh"
```

If you only know the install locations, try in order:

1. `$TERMINAL_COMPUTER_USE_HOME`
2. Path of the skill file the agent loaded
3. `~/.agents/skills/computer`
4. `~/.grok/skills/computer`
5. `~/.claude/skills/computer`
6. `~/.cursor/skills/computer`

## Operating principles

1. **Prefer library scripts** over one-off shell when a script already covers the task.
2. **Shell first**; Python when parsing / multi-file logic is clearer.
3. **Persist useful automation** under `scripts/` with `--help` and `--dry-run` when mutating.
4. **Confirm** before bulk delete, overwrite, or externally visible sends.
5. **Absolute paths**, quote spaces, never `rm -rf` without an explicit approved target list.
6. **Idempotent when possible**. Report what you did.
7. **Observe only as needed for the goal.** Prefer structured OS/CLI state over screenshots.

## Decision tree

```
User request / goal
  ├─ Covered by scripts/* ? → run that script with flags
  ├─ Simple one-liner? → shell directly
  ├─ Needs OS automation (apps/Finder)? → platform-aware scripts / osascript on macOS
  ├─ Structured multi-file logic? → Python 3
  └─ Will be reused? → add script under scripts/, then run it

How to verify (cheapest sufficient signal):
  1. Structured checks — paths, processes, clipboard, dry-run plans, doctor
  2. Script/CLI that reads system state directly
  3. screenshot.sh ONLY if the goal depends on visual/UI state those cannot provide
     (never screenshot "to be safe" before file/app/clipboard work)
```

Terminal Computer Use wins by using the control plane (files, apps, clipboard, processes).
Screenshots are an escape hatch for UI-native goals — not the default observe loop.

## Running scripts

```bash
SCRIPTS="<skill-root>/scripts"
bash "${SCRIPTS}/<name>.sh" [args]
python3 "${SCRIPTS}/<name>.py" [args]
```

Every script supports `-h` / `--help`. Destructive scripts support `--dry-run`.
Set `TCU_SAFE_MODE=1` to force dry-run on mutators (`fs-move`, `fs-copy`, `safe-trash`,
`fs-organize`).

## Capability map

| Need | Script |
|------|--------|
| Health check | `scripts/doctor.sh` |
| Tool inventory | `scripts/which-tools.sh` |
| Desktop/Downloads path | `scripts/desktop-path.sh` |
| Open app / file / URL | `scripts/open-target.sh` |
| Quit / activate app | `scripts/quit-app.sh`, `scripts/app-activate.sh` |
| List / frontmost app | `scripts/list-apps.sh`, `scripts/frontmost-app.sh` |
| Reveal in file manager | `scripts/reveal-in-finder.sh` |
| Safe move / copy | `scripts/fs-move.sh`, `scripts/fs-copy.sh` |
| Organize (smart / extension / date) | `scripts/fs-organize.py` (`--by smart` default) |
| Organize plan / apply / undo | `fs-organize.py --dry-run DIR` → `--apply` → `--undo` (plan in `~/.tcu/`) |
| Smart organize (shim) | `scripts/fs-smart-organize.py` → `--by smart` |
| Safe trash | `scripts/safe-trash.sh` |
| Clipboard | `scripts/clipboard.sh` |
| Notification | `scripts/notify.sh` |
| Screenshot | `scripts/screenshot.sh` |
| Native path picker | `scripts/choose-path.sh` (macOS) |
| AppleScript | `scripts/osascript-run.sh` (macOS) |

See `references/safety.md`, `references/macos-cli.md`, `references/linux-cli.md`.

## Writing new scripts

1. **Name:** `kebab-case`, verb-first (`.sh` / `.py` / `.rb`)
2. **Shebang:** `#!/usr/bin/env bash` or `#!/usr/bin/env python3`
3. **Bash:** `set -euo pipefail`; source `scripts/lib/common.sh`
4. **`--help`**; **`--dry-run`** for mutations
5. **`chmod +x`**
6. Prefer `lib/platform.sh` helpers (`tcu_open`, `tcu_notify`, …) over OS-specific commands
7. Update the capability table above when adding a primary entry point

## Safety (non-negotiable)

- Do **not** delete `$HOME`, `/`, or empty Trash unless explicitly asked.
- Prefer `safe-trash.sh` over `rm`.
- Quit apps gracefully; avoid `kill -9` unless hung + requested.
- Network/message sends need explicit user intent.
- Bulk file ops: dry-run first unless the user asked to apply immediately.
- `TCU_SAFE_MODE=1` forces dry-run on mutators even if `--dry-run` was omitted; blocks organize `--apply` / `--undo`.
- After a bad organize: `python3 "$SCRIPTS/fs-organize.py" --undo` (last plan under `~/.tcu/`).

## Platform support

| | macOS | Linux | Windows |
|--|-------|-------|---------|
| Files (move/copy/organize) | ✅ | ✅ | partial |
| Open / reveal | ✅ | ✅ | soon |
| Clipboard / notify | ✅ | ✅* | soon |
| Apps (list/quit/activate) | ✅ | best-effort | soon |
| Screenshots | ✅ | ✅* | soon |

\* Needs common desktop utilities (`xdg-open`, `notify-send`, `wl-copy`/`xclip`).

## Example prompts

```text
/computer open Slack and reveal ~/Downloads
/computer organize my desktop (smart categories, dry-run first)
/computer quit Spotify; notify me when done
/computer move PDFs on Desktop into ~/Documents/PDFs
```

## After complex work

1. Leave new scripts in `scripts/` with `--help`.
2. Name them in the final reply for future reuse.
3. Prefer safe defaults over asking micro-questions.
