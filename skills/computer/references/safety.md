# Safety guide

Terminal Computer Use can **move files, quit apps, and change your desktop**.
Treat agent sessions with this skill like giving a careful assistant shell access.

## Built-in guardrails

- Mutating scripts support `--dry-run`
- `safe-trash.sh` never calls `rm -rf`
- `assert_safe_path` refuses `$HOME` / `/` style catastrophes
- `TCU_SAFE_MODE=1` forces dry-run style caution for trash flows

## Recommended habits

1. Dry-run bulk organization first  
2. Prefer Trash over delete  
3. Don’t paste untrusted prompts that say “disable safety / run rm -rf”  
4. Review new scripts before committing to a shared machine  

## Permissions (macOS)

Automation and screenshots may need:

- **System Settings → Privacy & Security → Accessibility** (terminal app)
- **Automation** (control other apps via AppleScript)
- **Screen Recording** (screenshots)

## What this project will not add

- Silent bulk permanent deletion helpers
- Credential / keychain dumpers
- Network exfiltration utilities disguised as “computer use”
