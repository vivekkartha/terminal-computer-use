# Security Policy

## Threat model

Terminal Computer Use lets an AI coding agent run shell scripts that **move files,
open/quit apps, and change clipboard state** on your machine. It does **not**
automate browsers (no Playwright/DOM control).

| Assume | Do not assume |
|--------|----------------|
| You trust the agent product and model you use | Untrusted paste-prompts are safe |
| You review dry-runs for bulk file ops | The skill blocks all bad agent ideas |
| You run as a normal user (not root) | Network isolation is provided |

Only enable this skill in agents and accounts you control — it is effectively
shell access for desktop tasks.

## Reporting vulnerabilities

If a script can be tricked into deleting `$HOME`, path traversal, command injection,
or similar:

1. **Do not** open a public GitHub issue with exploit details.
2. Use **private vulnerability reporting** on GitHub:  
   [Report a vulnerability](https://github.com/vivekkartha/terminal-computer-use/security/advisories/new)  
   (Security → Advisories → Report a vulnerability)

Include: affected script, reproduction steps, impact, OS.

See also [docs/TRUST.md](docs/TRUST.md) for what we do and do not claim.

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | ✅ |
| 0.1.x   | best-effort |
| &lt; 0.1 | no |

## Hardening tips

- `./install.sh --dry-run` before install  
- `bash …/scripts/doctor.sh` after install  
- `--dry-run` on organize/move first  
- `TCU_SAFE_MODE=1` in sensitive environments  
- Never run agent sessions as root  
- Prefer `safe-trash.sh` over `rm`  
