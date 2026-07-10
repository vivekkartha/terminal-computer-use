# Contributing

Thanks for helping make Terminal Computer Use better.

## Dev setup

```bash
git clone https://github.com/vivekkartha/terminal-computer-use.git
cd terminal-computer-use
./install.sh --symlink --agent grok   # or --agent claude
bash skills/computer/scripts/doctor.sh
bash tests/test_scripts_help.sh
```

## Guidelines

1. **Scripts over prompts** — real automation lives in `skills/computer/scripts/`.
2. **Portable paths** — never hardcode `~/.grok` or other agent-only paths.
3. Use `lib/common.sh` + `lib/platform.sh` for OS differences.
4. Every script needs `--help`; mutating scripts need `--dry-run`.
5. Add/adjust tests under `tests/`.
6. Keep the product focused: desktop/files/apps via terminal — not browser-use, not vision CU.

## PR checklist

- [ ] `bash tests/test_scripts_help.sh` passes
- [ ] `python3 tests/test_fs_smart_organize.py` passes
- [ ] `./install.sh --dry-run` works
- [ ] SKILL.md capability table updated if you added an entry point
- [ ] No secrets or machine-specific paths committed

## Good first issues

- Linux notify/clipboard edge cases
- Windows PowerShell shims
- More organize strategies (by project name, by date hierarchy)
- Demo GIF / asciinema improvements
