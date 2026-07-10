# Copy-paste prompt for any coding agent

Paste the block below into Claude Code, Cursor, Codex, Grok, Gemini CLI, Windsurf, or any agent with shell access. It bootstraps **Terminal Computer Use** (`/computer`) without relying on a preinstalled skill.

---

## Prompt (copy everything in the fence)

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
- macOS app control may need Accessibility/Automation for the terminal app.
- Report what you ran and what changed.

## Key commands
SCRIPTS=<skill-root>/scripts
bash "$SCRIPTS/doctor.sh"
python3 "$SCRIPTS/fs-organize.py" --dry-run ~/Desktop
python3 "$SCRIPTS/fs-organize.py" ~/Desktop
bash "$SCRIPTS/fs-move.sh" --dry-run <src> <dest>
bash "$SCRIPTS/open-target.sh" <app-or-path-or-url>
bash "$SCRIPTS/notify.sh" --title TCU "done"
bash "$SCRIPTS/clipboard.sh" get|set <text>
bash "$SCRIPTS/safe-trash.sh" --dry-run <path>

## When I say /computer or "computer use"
Treat the rest of the message as the task. Use the skill + scripts above. Be autonomous with safe defaults; only ask when the action is destructive or ambiguous at high blast radius.

Confirm bootstrap with one line: skill path + doctor summary (ok/warn/fail). Then do my task.
```

---

## Short variant (if the agent already has the skill installed)

```text
Use Terminal Computer Use: read your computer skill SKILL.md (or ~/.agents/skills/computer/SKILL.md), set SCRIPTS to its scripts/ dir, run doctor if unsure, then handle my request with those scripts. Dry-run bulk file ops first. Prefer library scripts over ad-hoc shell.

Task: <describe what you want>
```

---

## Example tasks to append

```text
/computer organize my desktop (dry-run first, then apply if safe)
/computer open Slack and reveal ~/Downloads
/computer move PDFs on Desktop into ~/Documents/PDFs
/computer quit Spotify and notify me when done
```
