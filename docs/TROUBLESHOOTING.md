# Troubleshooting

## Install

### Skill not showing in my agent

1. Confirm install path exists:
   ```bash
   ls ~/.agents/skills/computer/SKILL.md
   ls ~/.claude/skills/computer/SKILL.md   # Claude Code
   ls ~/.grok/skills/computer/SKILL.md     # Grok
   ls ~/.cursor/skills/computer/SKILL.md   # Cursor
   ```
2. Re-run from the repo:
   ```bash
   ./install.sh --dry-run
   ./install.sh
   ```
3. Restart the agent / start a new session (skills load at session start).
4. Project vs global: `./install.sh --project` only affects the current repo.

### `skip (unmanaged)` / nothing installed

A directory already exists without a TCU marker. Either:

```bash
# only if that folder is disposable
rm -rf ~/.agents/skills/computer
./install.sh
```

or:

```bash
./install.sh --force
```

### `npx skills add` issues

```bash
npx skills add vivekkartha/terminal-computer-use -l    # list
npx skills add vivekkartha/terminal-computer-use -g -y # global install
```

If the CLI can’t find the skill, clone and `./install.sh` instead.

---

## Runtime

### App quit / list / notify fails on macOS

Grant your **terminal app** (Terminal, iTerm, Ghostty, VS Code, …):

- **System Settings → Privacy & Security → Accessibility**
- **Automation** (control System Events / other apps)
- **Screen Recording** (for screenshots)

Then re-run:

```bash
bash ~/.agents/skills/computer/scripts/doctor.sh
```

### Clipboard / notify missing on Linux

```bash
# Debian/Ubuntu examples
sudo apt install xdg-utils libnotify-bin wl-clipboard
# or: xclip, trash-cli
```

### Organize moved the wrong things

Always dry-run first:

```bash
python3 "$S/fs-organize.py" --dry-run ~/Desktop
```

- Smart mode skips existing folders (won’t recurse into `Images/`).
- `.txt` files go under **Documents**.
- Use `--by extension` or `--by date` for other layouts.

### Paths with spaces

Quote them; do not rely on unquoted globs inside the script:

```bash
bash "$S/fs-move.sh" --dry-run ~/Desktop/"My File.pdf" ~/Documents/
```

### Agent did something destructive

- Prefer `TCU_SAFE_MODE=1` in sensitive environments.
- Use `safe-trash.sh` (never a bulk `rm -rf` helper in this project).
- Review [SECURITY.md](../SECURITY.md).

---

## Platform support

| | Status |
|--|--------|
| macOS | Full |
| Linux | Core (files, open, clipboard, notify with desktop utils) |
| Windows | **Not supported** yet |

---

## Still stuck?

1. `bash …/scripts/doctor.sh` — paste output  
2. Open a [bug report](https://github.com/vivekkartha/terminal-computer-use/issues/new?template=bug_report.md)  
3. Security issues → private advisory, not a public issue ([SECURITY.md](../SECURITY.md))
