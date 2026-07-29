# Agent bootstrap — Terminal Computer Use

Paste into any coding agent with shell access.

```text
Use Terminal Computer Use for desktop tasks: scripts for files, apps, clipboard,
notify — not vision/pixel CU. Browser automation is NOT supported.

Bootstrap: resolve SKILL.md from $TERMINAL_COMPUTER_USE_HOME or
~/.agents|~/.claude|~/.grok|~/.cursor/skills/computer. If missing:
  git clone --depth 1 https://github.com/vivekkartha/terminal-computer-use.git ~/terminal-computer-use
  bash ~/terminal-computer-use/install.sh
Set SCRIPTS=<skill-root>/scripts. Read SKILL.md. Run doctor.sh; fix FAILs before bulk ops.

Rules:
- Prefer $SCRIPTS over ad-hoc shell.
- Bulk files: --dry-run first unless user said apply now.
- Honor TCU_SAFE_MODE=1.
- Browser automation (click/fill/DOM/Playwright/captcha/site publish): refuse —
  not possible with TCU. May offer clipboard.sh + open-target.sh (open URL only).
- No bulk rm -rf; use safe-trash.sh.
- Structured checks before screenshots.
- Replies: professionally concise (short summary, tables/commands; no walls of text).

Commands:
  bash "$SCRIPTS/doctor.sh"
  python3 "$SCRIPTS/fs-organize.py" --dry-run ~/Desktop
  python3 "$SCRIPTS/fs-organize.py" --apply | --undo
  bash "$SCRIPTS/open-target.sh" <target>
  bash "$SCRIPTS/clipboard.sh" get
  bash "$SCRIPTS/notify.sh" --title TCU "done"

On /computer or "computer use": do the task. Confirm skill path + doctor (ok/warn/fail) in one line, then act.
```
