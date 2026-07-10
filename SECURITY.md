# Security Policy

## What this software can do

Terminal Computer Use is a skill + script library that lets AI coding agents
operate your machine through the shell (open apps, move files, clipboard, etc.).

**That is powerful and inherently risky.** Only install and enable it in agents
you trust, on machines you control.

## Reporting vulnerabilities

If you find a security issue (e.g. a script that can be tricked into deleting
`$HOME`, path traversal, command injection):

1. **Do not** open a public GitHub issue with exploit details.
2. Email the maintainer via GitHub profile contact, or open a **private**
   security advisory on the GitHub repository.

Please include: affected script, reproduction steps, and impact.

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.x     | ✅ best-effort |

## Hardening tips for users

- Prefer `./install.sh --dry-run` then install
- Run `bash scripts/doctor.sh` after install
- Use `--dry-run` on organize/move operations first
- Set `TCU_SAFE_MODE=1` in sensitive environments
- Do not run agent sessions as root
