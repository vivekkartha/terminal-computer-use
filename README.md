# Terminal Computer Use

**Give Claude Code / Cursor / Codex / Grok a safe desktop:** organize files, open apps, clipboard, notify — via shell scripts, not screenshots + mouse.

```bash
npx skills add vivekkartha/terminal-computer-use -g
# then in your agent:
/computer organize my desktop   # dry-run first
```

[![Release](https://img.shields.io/github/v/release/vivekkartha/terminal-computer-use?style=flat)](https://github.com/vivekkartha/terminal-computer-use/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Install](https://img.shields.io/badge/install-npx%20skills-black)](https://github.com/vercel-labs/skills)

| | |
|--|--|
| **For** | Coding agents with a terminal (Claude Code, Cursor, Codex, Grok, Gemini CLI, …) |
| **Platforms** | macOS full · Linux core · Windows not yet |
| **Alt install** | `git clone … && ./install.sh && doctor` |

## Why not vision Computer Use?

| Vision / pixel CU | This skill |
|-------------------|------------|
| Screenshots → model guesses clicks | Scripts call the OS directly |
| Slow, flaky, expensive tokens | Fast, deterministic, loggable |
| Easy to misclick the wrong UI | `--dry-run`, undo, path guards |

**Not browser automation.** Captcha and bot checks defeat that. Open a URL only (`open-target.sh`); humans own the page.

## 30-second demo

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use && bash demos/scripts/demo-organize.sh
```

Messy fixture → smart folders (`Screenshots/`, `Images/`, `Documents/`, …) with plan → apply → undo.

## What you get

| Job | Script |
|-----|--------|
| Organize (plan / apply / undo) | `fs-organize.py` |
| Move / copy / trash | `fs-move.sh` · `fs-copy.sh` · `safe-trash.sh` |
| Open app / file / URL | `open-target.sh` |
| Apps / clipboard / notify | `quit-app.sh` · `clipboard.sh` · `notify.sh` |
| Health | `doctor.sh` |

Agent paste-prompt: [docs/AGENT_PROMPT.md](docs/AGENT_PROMPT.md) · Permissions: [TROUBLESHOOTING](docs/TROUBLESHOOTING.md).

## Safety

- Mutators support `--dry-run` · `TCU_SAFE_MODE=1` blocks mutations  
- Organize undo: `fs-organize.py --undo`  
- No telemetry · [SECURITY](SECURITY.md) · [TRUST](docs/TRUST.md)

## Develop

```bash
./install.sh --symlink
bash tests/smoke_release.sh
```

MIT © [Vivek Kartha](https://github.com/vivekkartha)
