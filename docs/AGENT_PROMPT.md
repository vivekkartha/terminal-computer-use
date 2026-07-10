# Copy-paste prompt for any coding agent

Paste the block below into Claude Code, Cursor, Codex, Grok, Gemini CLI, Windsurf, or any agent with shell access. It loads **Terminal Computer Use** (shell desktop automation — not vision Computer Use).

---

## Prompt (copy everything inside the fence)

```text
Use Terminal Computer Use for desktop tasks in this session: control files, apps, clipboard, and notifications via shell scripts — not screenshots or mouse clicks.

## Bootstrap (once per machine if the skill is missing)
1. Find SKILL.md (first match wins):
   - $TERMINAL_COMPUTER_USE_HOME
   - ~/.agents/skills/computer
   - ~/.claude/skills/computer
   - ~/.grok/skills/computer
   - ~/.cursor/skills/computer
2. If missing, install permanently (not only /tmp):
   git clone --depth 1 https://github.com/vivekkartha/terminal-computer-use.git ~/terminal-computer-use
   bash ~/terminal-computer-use/install.sh
   Re-check the paths above.
3. Set SCRIPTS to <skill-root>/scripts
4. Read <skill-root>/SKILL.md and follow it.
5. Run: bash "$SCRIPTS/doctor.sh" — fix any FAIL before bulk file operations.

## Working rules
- Prefer scripts under $SCRIPTS over one-off shell.
- For bulk file changes: --dry-run first unless the user explicitly asked to apply immediately.
- Honor TCU_SAFE_MODE=1 (forces dry-run on mutators).
- Quote paths that contain spaces; expand globs in the shell before calling scripts.
- Do not bulk rm -rf user data; use safe-trash.sh for deletes.
- Refuse catastrophic targets ($HOME, /, system paths).
- macOS app control may need Accessibility/Automation for the terminal app.
- Say what you ran and what changed.

## Useful commands
SCRIPTS=<skill-root>/scripts
bash "$SCRIPTS/doctor.sh"
python3 "$SCRIPTS/fs-organize.py" --dry-run ~/Desktop
python3 "$SCRIPTS/fs-organize.py" ~/Desktop
bash "$SCRIPTS/fs-move.sh" --dry-run <src> <dest>
bash "$SCRIPTS/open-target.sh" <app-or-path-or-url>
bash "$SCRIPTS/notify.sh" --title TCU "done"
bash "$SCRIPTS/clipboard.sh" get
bash "$SCRIPTS/safe-trash.sh" --dry-run <path>

## Tasks
If the user says /computer or "computer use", treat the rest as the task. Prefer safe defaults; ask only when the action is highly destructive or ambiguous.

Reply with one line confirming skill path + doctor result (ok/warn/fail), then do the task.
```

---

## Short variant (skill already installed)

```text
Use Terminal Computer Use: read SKILL.md under ~/.agents/skills/computer (or ~/.claude / ~/.grok / ~/.cursor), set SCRIPTS to its scripts/ directory, run doctor if needed, then handle my request with those scripts. Dry-run bulk file ops first. Prefer library scripts over ad-hoc shell.

Task: <describe what you want>
```

---

## Example tasks

```text
organize my desktop (dry-run first, then apply if the plan looks right)
open Slack and reveal ~/Downloads
move PDFs on Desktop into ~/Documents/PDFs
quit Spotify and send a notification when done
```
