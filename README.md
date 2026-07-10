# Terminal Computer Use

**Shell-based desktop automation for coding agents** — not Anthropic/OpenAI vision Computer Use, not pixel clicking.

Open apps, organize files, clipboard, notifications, screenshots. Works with Claude Code, Cursor, Codex, Grok, Gemini CLI, and any agent that can run shell commands.

[![Release](https://img.shields.io/github/v/release/vivekkartha/terminal-computer-use?style=flat)](https://github.com/vivekkartha/terminal-computer-use/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://skills.sh)

| Vision Computer Use | This project |
|---------------------|--------------|
| Screenshots + mouse | Shell + scripts |
| Expensive, flaky UI | Fast, repeatable CLI |
| Needs a display | Works over SSH |

**Platforms:** macOS (full) · Linux (files + common desktop tools) · Windows (not supported)

---

## Install

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use
./install.sh
bash ~/.agents/skills/computer/scripts/doctor.sh
```

If you use the Agent Skills CLI:

```bash
npx skills add vivekkartha/terminal-computer-use -g
```

Installer options: `--dry-run` · `--symlink` · `--agent claude` · `--force` · `--all-agents`

---

## Use with a coding agent

1. Install (above), or let the agent install via the prompt.
2. Copy the bootstrap prompt from **[docs/AGENT_PROMPT.md](docs/AGENT_PROMPT.md)** into your agent.
3. Ask for a task, e.g. `organize my desktop` or `open Slack and reveal ~/Downloads`.

Some agents register a `/computer` skill after install; others only need natural language + the prompt.

### Quick CLI check

```bash
./demos/scripts/demo-organize.sh

S=~/.agents/skills/computer/scripts   # or ~/.claude / ~/.grok / ~/.cursor
python3 "$S/fs-organize.py" --dry-run ~/Desktop
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `fs-organize.py` | Sort files by smart categories, extension, or date |
| `fs-move.sh` / `fs-copy.sh` | Move/copy (supports spaces; `--dry-run`) |
| `safe-trash.sh` | Move to Trash (not `rm -rf`) |
| `open-target.sh` | Open app, file, folder, or URL |
| `quit-app.sh` / `app-activate.sh` | Quit or focus an app |
| `list-apps.sh` / `frontmost-app.sh` | List or focus frontmost app |
| `clipboard.sh` / `notify.sh` / `screenshot.sh` | Clipboard, notification, capture |
| `doctor.sh` | Health check |

---

## Safety

- File changes support `--dry-run`; set `TCU_SAFE_MODE=1` to force dry-run on mutators
- Avoids deleting `$HOME` / system paths; installer will not overwrite unmanaged skill dirs without `--force`
- No analytics or telemetry in the scripts or installer
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
