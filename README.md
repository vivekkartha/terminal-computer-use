# Terminal Computer Use

**Computer Use for any coding agent — via the terminal, not pixel clicking.**

Open apps, organize files, clipboard, notify, screenshots. Works with Claude Code, Cursor, Codex, Grok, Gemini CLI, and any agent that can run shell commands.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://skills.sh)

| Vision Computer Use | **This** |
|---------------------|----------|
| Screenshots + mouse | Shell + scripts |
| Expensive, flaky UI | Fast, idempotent CLI |
| Needs a display | Works over SSH |

---

## Install

```bash
npx skills add vivekkartha/terminal-computer-use -g
```

Or:

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use && ./install.sh
```

`./install.sh` copies the skill into agent dirs it finds (`~/.claude`, `~/.grok`, `~/.cursor`, `~/.agents`). Use `--dry-run`, `--symlink`, or `--agent claude` as needed.

```bash
bash ~/.agents/skills/computer/scripts/doctor.sh
```

---

## Use

**In your agent**

```text
/computer organize my desktop
/computer open Slack and reveal ~/Downloads
/computer quit Spotify; notify me when done
```

**CLI**

```bash
S=~/.agents/skills/computer/scripts   # or ~/.grok / ~/.claude path

python3 "$S/fs-organize.py" --dry-run ~/Desktop
python3 "$S/fs-organize.py" ~/Desktop

bash "$S/fs-move.sh" --dry-run ~/Desktop/"report final.pdf" ~/Documents/
bash "$S/notify.sh" --title "Done" "Desktop organized"
```

---

## Scripts

| | |
|--|--|
| `fs-organize.py` | Smart / extension / date folders (`--by smart`) |
| `fs-move.sh` `fs-copy.sh` | Move/copy · spaces OK · `--dry-run` |
| `safe-trash.sh` | Trash only (no `rm -rf`) |
| `open-target.sh` | App / file / URL |
| `quit-app.sh` `app-activate.sh` | Quit / focus |
| `list-apps.sh` `frontmost-app.sh` | Running / focused |
| `clipboard.sh` `notify.sh` `screenshot.sh` | Clipboard, notify, capture |
| `doctor.sh` | Health check |

macOS is fully supported; Linux covers files, open/reveal, clipboard, notify (with desktop utils).

---

## Safety

- Mutators support `--dry-run`; `TCU_SAFE_MODE=1` forces dry-run
- Refuses `$HOME` / system paths; installer won’t clobber unmanaged dirs without `--force`
- Details: [SECURITY.md](SECURITY.md)

---

## Dev

```bash
./install.sh --symlink
bash tests/test_scripts_help.sh && bash tests/test_fs_move.sh
python3 tests/test_fs_smart_organize.py && bash tests/test_install_dry.sh
```

MIT © [Vivek Kartha](https://github.com/vivekkartha)
