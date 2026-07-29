# Terminal Computer Use

Shell automation for coding agents: files, apps, clipboard, notify.  
Not vision/pixel computer-use. **No browser automation** (captcha/bot checks make it unreliable).

| | |
|--|--|
| **Platforms** | macOS full · Linux core · Windows unsupported |
| **Install** | `npx skills add vivekkartha/terminal-computer-use -g` then `doctor.sh` |
| **Or** | `git clone … && ./install.sh && doctor` |

[![Release](https://img.shields.io/github/v/release/vivekkartha/terminal-computer-use?style=flat)](https://github.com/vivekkartha/terminal-computer-use/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Quick start

```bash
S=~/.agents/skills/computer/scripts   # or ~/.grok / ~/.claude — see doctor
bash "$S/doctor.sh"
python3 "$S/fs-organize.py" --dry-run ~/Desktop
```

Agent bootstrap: [docs/AGENT_PROMPT.md](docs/AGENT_PROMPT.md) · macOS Accessibility/Automation if app control fails: [TROUBLESHOOTING](docs/TROUBLESHOOTING.md).

## Capabilities

| Job | Script |
|-----|--------|
| Organize (plan/apply/undo) | `fs-organize.py` |
| Move / copy / trash | `fs-move.sh` · `fs-copy.sh` · `safe-trash.sh` |
| Open app/file/URL | `open-target.sh` (URL = open only; no page control) |
| Apps / clipboard / notify | `quit-app.sh` · `clipboard.sh` · `notify.sh` |
| Health | `doctor.sh` |

**Not supported:** browser DOM click/fill, Playwright, captcha, automated site publish. Agents should refuse those requests and optionally offer clipboard + open URL only.

## Safety

- `--dry-run` on mutators · `TCU_SAFE_MODE=1` blocks mutations  
- Organize undo: `fs-organize.py --undo` (`~/.tcu/`)  
- No telemetry  
- [SECURITY](SECURITY.md) · [TRUST](docs/TRUST.md)

## Develop

```bash
./install.sh --symlink
bash tests/smoke_release.sh
```

**Docs style:** short, professional, scannable. Prefer tables and commands over prose.

MIT © [Vivek Kartha](https://github.com/vivekkartha)
