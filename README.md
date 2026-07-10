# Terminal Computer Use

**Computer Use for any coding agent — via the terminal, not pixel clicking.**

Give [Claude Code](https://claude.ai/code), [Cursor](https://cursor.com), Codex, [Grok](https://x.ai), Gemini CLI, OpenCode, and friends **real hands** on your machine using shell scripts: open apps, organize your Desktop, move files safely, clipboard, notifications, screenshots.

No vision API. No brittle click loops. Works over SSH. MIT licensed.

[![CI](https://github.com/vivekkartha/terminal-computer-use/actions/workflows/ci.yml/badge.svg)](https://github.com/vivekkartha/terminal-computer-use/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://skills.sh)

---

## Why this exists

| Vision “Computer Use” | **Terminal Computer Use** |
|----------------------|---------------------------|
| Screenshots + mouse | Shell + scripts + OS automation |
| Expensive / slow | Cheap / fast |
| Flaky UI selectors | Idempotent CLI ops |
| Needs a display | Works headless / remote |
| Vendor-locked APIs | **Any agent with a terminal** |

> Your agent already has a shell. This skill teaches it to use that shell like a careful power user.

---

## Install (30 seconds)

### Option A — Agent Skills CLI (recommended)

```bash
npx skills add vivekkartha/terminal-computer-use -g
```

### Option B — Installer script

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use
./install.sh
```

Installs into whatever agents it finds:

| Agent | Path |
|-------|------|
| Grok | `~/.grok/skills/computer/` |
| Claude Code | `~/.claude/skills/computer/` |
| Cursor | `~/.cursor/skills/computer/` |
| Generic / Codex | `~/.agents/skills/computer/` |

```bash
./install.sh --dry-run          # preview
./install.sh --symlink          # dev mode
./install.sh --agent claude     # one agent
./install.sh --project          # current repo only
```

### Verify

```bash
bash ~/.agents/skills/computer/scripts/doctor.sh
# or wherever install.sh put it:
bash ~/.grok/skills/computer/scripts/doctor.sh
```

---

## Quick start

In your coding agent:

```text
/computer organize my desktop
/computer open Slack and reveal ~/Downloads
/computer quit Spotify; notify me when done
/computer move all PDFs on Desktop into ~/Documents/PDFs — dry-run first
```

Or call scripts directly:

```bash
SCRIPTS=~/.grok/skills/computer/scripts   # or your install path

bash "$SCRIPTS/desktop-path.sh"
python3 "$SCRIPTS/fs-smart-organize.py" --dry-run ~/Desktop
python3 "$SCRIPTS/fs-smart-organize.py" ~/Desktop
bash "$SCRIPTS/notify.sh" --title "Done" "Desktop organized"
```

---

## What you get

### Skill (`skills/computer/SKILL.md`)

Instructions any agent can follow: when to run which script, safety rules, how to add new automation.

### Script library (the product)

| Script | Purpose |
|--------|---------|
| `doctor.sh` | Health check |
| `which-tools.sh` | Tool inventory |
| `desktop-path.sh` | Desktop / Downloads paths |
| `open-target.sh` | Open app / file / URL |
| `app-activate.sh` | Focus app (macOS) |
| `quit-app.sh` | Quit app |
| `list-apps.sh` / `frontmost-app.sh` | Running / focused apps |
| `reveal-in-finder.sh` | Reveal in file manager |
| `fs-move.sh` / `fs-copy.sh` | Safe move/copy + `--dry-run` |
| `fs-organize.py` | By extension or date |
| `fs-smart-organize.py` | Screenshots / Images / Docs / … |
| `safe-trash.sh` | Trash, never `rm -rf` |
| `clipboard.sh` | get / set / clear |
| `notify.sh` | Desktop notification |
| `screenshot.sh` | Capture screen |
| `choose-path.sh` | Native file picker (macOS) |
| `osascript-run.sh` | AppleScript (macOS) |

Platform helpers live in `scripts/lib/platform.sh` (macOS + Linux core).

---

## Platform support

| Capability | macOS | Linux | Windows |
|------------|:-----:|:-----:|:-------:|
| Files move/copy/organize | ✅ | ✅ | soon |
| Open / reveal | ✅ | ✅ | soon |
| Clipboard / notify | ✅ | ✅* | soon |
| Apps list/quit | ✅ | best-effort | soon |
| Screenshots | ✅ | ✅* | soon |

\* Needs common desktop utilities (`xdg-open`, `notify-send`, `wl-copy`/`xclip`).

---

## Safety

This can **move files and quit apps**. Built-in guardrails:

- `--dry-run` on mutating scripts  
- `safe-trash.sh` (no silent `rm -rf`)  
- Refuse catastrophic paths  
- Optional `TCU_SAFE_MODE=1`  

Read [SECURITY.md](SECURITY.md) and [skills/computer/references/safety.md](skills/computer/references/safety.md).

---

## How it works

```text
You → Coding agent (/computer)
        → reads SKILL.md
        → runs scripts next to the skill
        → bash / python / osascript / xdg-open
        → your OS does the work
```

No cloud “computer use” API. The agent’s existing terminal tool is enough.

---

## Demo (CLI)

```bash
./demos/scripts/demo-organize.sh
```

Record a GIF for your own README fork — see [demos/assets/README.md](demos/assets/README.md).

---

## Development

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use
./install.sh --symlink --agent grok
bash tests/test_scripts_help.sh
python3 tests/test_fs_smart_organize.py
bash tests/test_install_dry.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Not this project

- ❌ Browser automation → try [agent-browser](https://github.com/vercel-labs/agent-browser) / Playwright  
- ❌ Pixel-level GUI Computer Use APIs  
- ❌ A dump of 300 AI-generated skill files  

This is **one sharp product**: terminal-native desktop ops for agents.

---

## Launch / share

If this saves you time, **star the repo** and share:

> Terminal Computer Use — Computer Use for any coding agent, via the shell.  
> `npx skills add vivekkartha/terminal-computer-use -g`

---

## License

[MIT](LICENSE) © 2026 Vivek Kartha
