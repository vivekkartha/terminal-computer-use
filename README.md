# Terminal Computer Use

**Shell-based desktop automation for coding agents** — not Anthropic/OpenAI vision Computer Use, not pixel clicking.

Give your agent a safe way to **organize files, open/quit apps, use the clipboard, send notifications, and (optionally) drive pages via Playwright DOM** via scripts. Fast, repeatable, works over SSH.

| Vision Computer Use | This project |
|---------------------|--------------|
| Screenshots + mouse | Shell + scripts (+ optional Playwright selectors) |
| Expensive, flaky UI | Fast, repeatable CLI |
| Needs a display | Works over SSH (browser optional headed) |

**For:** coding agents with shell access (Claude Code, Cursor, Codex, Grok, Gemini CLI, …)  
**Not for:** vision/pixel clicking, silent auto-publish, or Windows (not supported)

**Platforms:** macOS (full) · Linux (files + common desktop tools) · Windows (not supported)

[![Release](https://img.shields.io/github/v/release/vivekkartha/terminal-computer-use?style=flat)](https://github.com/vivekkartha/terminal-computer-use/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://skills.sh)

---

## Install

**Prefer Agent Skills CLI** (if you use it):

```bash
npx skills add vivekkartha/terminal-computer-use -g
bash ~/.agents/skills/computer/scripts/doctor.sh
```

**Otherwise** clone and install into agent skill dirs:

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use
./install.sh
bash ~/.agents/skills/computer/scripts/doctor.sh
```

Installer options: `--dry-run` · `--symlink` · `--agent claude` · `--force` · `--all-agents`

The installer copies the skill into agent homes it finds (`~/.agents`, `~/.claude`, `~/.grok`, `~/.cursor`, …). `doctor` prints the path it resolved.

**macOS:** if app control fails later, grant **Accessibility** and **Automation** to your terminal app, then re-run `doctor`. Details: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## First success

You’re set when:

1. **Doctor has no `FAIL`** (WARN is often OK on Linux without optional tools)
2. **Demo or dry-run works** without moving real files
3. **Your agent can run a task** (next section)

```bash
# from a clone
./demos/scripts/demo-organize.sh

# or against a real folder (plan only — no moves)
S=~/.agents/skills/computer/scripts   # or ~/.claude / ~/.grok / ~/.cursor — see doctor output
python3 "$S/fs-organize.py" --dry-run ~/Desktop
```

---

## Use with a coding agent

1. Install (above).
2. Paste the bootstrap prompt from **[docs/AGENT_PROMPT.md](docs/AGENT_PROMPT.md)** into a new agent session  
   *(some agents also expose `/computer` after install)*.
3. Ask in plain language:

```text
organize my desktop — dry-run first, then apply if the plan looks right
```

```text
open Slack and reveal ~/Downloads
```

```text
move PDFs on Desktop into ~/Documents/PDFs
```

```text
quit Spotify and notify me when done
```

Prefer library scripts over ad-hoc shell. Prefer path/process checks over screenshots unless the goal is visual UI.

---

## Safe desktop organize

Bulk organize is reversible via a plan file (`~/.tcu/last-organize-plan.json`):

```bash
S=~/.agents/skills/computer/scripts

python3 "$S/fs-organize.py" --dry-run ~/Desktop   # write plan, no moves
python3 "$S/fs-organize.py" --apply                 # run last plan
python3 "$S/fs-organize.py" --undo                  # reverse last apply

# or one-shot execute (still records a plan you can --undo)
python3 "$S/fs-organize.py" ~/Desktop
```

Cautious sessions: `TCU_SAFE_MODE=1` forces dry-run on mutators and blocks apply/undo.

---

## What you can do

| Job | How |
|-----|-----|
| Organize Desktop / Downloads | `fs-organize.py` (`--dry-run` / `--apply` / `--undo`) |
| Move or copy files safely | `fs-move.sh` / `fs-copy.sh` |
| Trash (not `rm -rf`) | `safe-trash.sh` |
| Open app, file, folder, URL | `open-target.sh` |
| Quit or focus an app | `quit-app.sh` / `app-activate.sh` |
| List / frontmost app | `list-apps.sh` / `frontmost-app.sh` |
| Clipboard / notification | `clipboard.sh` / `notify.sh` |
| Screenshot (when UI state is required) | `screenshot.sh` |
| Browser DOM click/fill (optional Playwright) | `browser.sh` |
| Medium draft / gated publish | `browser.sh medium-draft` · `medium-publish --i-mean-it` |
| Health check | `doctor.sh` |

Scripts live under the installed skill’s `scripts/` directory (see `doctor`).

---

## Safety

- Mutators support `--dry-run`; `TCU_SAFE_MODE=1` forces dry-run (move, copy, trash, organize)
- Organize plans under `~/.tcu/`; reverse with `fs-organize.py --undo`
- Refuses catastrophic targets (`$HOME`, `/`, system paths); installer won’t clobber unmanaged skill dirs without `--force`
- No analytics or telemetry
- This **can** move files and control apps — treat it like shell access you granted the agent

Details: [SECURITY.md](SECURITY.md) · [docs/TRUST.md](docs/TRUST.md) · [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## Development

```bash
./install.sh --symlink
bash tests/run_test_plan.sh    # full plan
bash tests/smoke_release.sh    # shorter gate
```

MIT © [Vivek Kartha](https://github.com/vivekkartha)
