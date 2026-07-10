# Terminal Computer Use

**Computer Use for any coding agent — via the terminal, not pixel clicking.**

Open apps, organize files, clipboard, notify, screenshots. Works with Claude Code, Cursor, Codex, Grok, Gemini CLI, and any agent that can run shell commands.

[![Release](https://img.shields.io/github/v/release/vivekkartha/terminal-computer-use?style=flat)](https://github.com/vivekkartha/terminal-computer-use/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-policy-blue.svg)](SECURITY.md)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://skills.sh)

| Vision Computer Use | **This** |
|---------------------|----------|
| Screenshots + mouse | Shell + scripts |
| Expensive, flaky UI | Fast, idempotent CLI |
| Needs a display | Works over SSH |

**Support:** macOS ✅ · Linux core ✅ · Windows ❌

---

## Install

```bash
npx skills add vivekkartha/terminal-computer-use -g
```

Or:

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use && ./install.sh
bash ~/.agents/skills/computer/scripts/doctor.sh
```

Options: `--dry-run` · `--symlink` · `--agent claude` · `--force` · `--all-agents`

---

## Start in any coding agent (copy-paste)

Paste this into Claude Code, Cursor, Codex, Grok, Gemini CLI, etc.:

```text
You now have Terminal Computer Use — desktop control via the shell (not vision/pixel clicking).

## Bootstrap (run once if needed)
1. Find the skill (first match wins):
   - $TERMINAL_COMPUTER_USE_HOME
   - ~/.agents/skills/computer
   - ~/.claude/skills/computer
   - ~/.grok/skills/computer
   - ~/.cursor/skills/computer
2. If SKILL.md is missing, install:
   git clone --depth 1 https://github.com/vivekkartha/terminal-computer-use.git /tmp/terminal-computer-use
   bash /tmp/terminal-computer-use/install.sh
   Then re-check the paths above.
3. Set SCRIPTS to <skill-root>/scripts
4. Read <skill-root>/SKILL.md and follow it for this session.
5. Run: bash "$SCRIPTS/doctor.sh" and fix any FAIL before bulk file ops.

## How to work
- Prefer library scripts under $SCRIPTS over one-off shell.
- Mutating file ops: --dry-run first unless I said to just do it.
- Honor TCU_SAFE_MODE=1 (forces dry-run on mutators).
- Paths with spaces: quote them. Expand globs in the shell before calling scripts.
- Never rm -rf bulk user data; use safe-trash.sh for deletes.
- Refuse catastrophic targets ($HOME, /, system paths).
- Report what you ran and what changed.

## When I say /computer or "computer use"
Treat the rest of the message as the task. Use the skill + scripts above. Be autonomous with safe defaults.

Confirm bootstrap with one line: skill path + doctor summary (ok/warn/fail). Then do my task.
```

Full prompt + short variant + examples: **[docs/AGENT_PROMPT.md](docs/AGENT_PROMPT.md)**

### Try in 30 seconds (CLI)

```bash
./demos/scripts/demo-organize.sh
# or after install:
S=~/.agents/skills/computer/scripts
python3 "$S/fs-organize.py" --dry-run ~/Desktop
```

---

## Scripts

| | |
|--|--|
| `fs-organize.py` | Smart / extension / date folders |
| `fs-move.sh` `fs-copy.sh` | Move/copy · spaces OK · `--dry-run` |
| `safe-trash.sh` | Trash only |
| `open-target.sh` `quit-app.sh` `app-activate.sh` | Open / quit / focus |
| `clipboard.sh` `notify.sh` `screenshot.sh` | Clipboard, notify, capture |
| `doctor.sh` | Health check |

---

## Trust & safety

| | |
|--|--|
| License | **MIT** — enterprise-friendly, no fees |
| Telemetry | **None** — scripts do not phone home |
| Defaults | `--dry-run`, `TCU_SAFE_MODE`, trash not `rm -rf`, path guards |
| Disclosure | [SECURITY.md](SECURITY.md) · private vulnerability reporting on GitHub |
| Supply chain | Dependabot enabled · public source · versioned releases |

This skill can move files and control apps **by design**. It is **not** a paid security certification (SOC 2 / ISO). For evaluators: [docs/TRUST.md](docs/TRUST.md).

More: [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## Dev / release gate

```bash
./install.sh --symlink
bash tests/smoke_release.sh
```

MIT © [Vivek Kartha](https://github.com/vivekkartha)
