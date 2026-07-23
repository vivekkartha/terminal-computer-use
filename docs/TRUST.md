# Trust & security

What this project claims, and what free signals support that. This is **not** a paid audit (SOC 2, ISO 27001, etc.).

## Claims

| Claim | Meaning |
|-------|---------|
| MIT license | Free to use, modify, and redistribute under [LICENSE](../LICENSE) |
| No telemetry | Installer and scripts do not send analytics |
| Open source | Full source on GitHub; inspect before you run |
| Safe defaults | `--dry-run` on mutators; trash over `rm -rf`; path guards |
| Disclosure | [SECURITY.md](../SECURITY.md) and private vulnerability reporting on GitHub |

## Not claimed

- Not “enterprise certified” or “guaranteed secure”
- Not a substitute for your organization’s agent or endpoint policy
- Not a third-party penetration test

By design, this skill can **move files and control apps**. Treat it as shell access you gave the agent.

## Verifiable on this repository

| Signal | Status |
|--------|--------|
| MIT license | Yes |
| SECURITY.md + threat model | Yes |
| Private vulnerability reporting | Yes ([report](https://github.com/vivekkartha/terminal-computer-use/security/advisories/new)) |
| Dependabot config | Yes (`.github/dependabot.yml`) |
| Automated tests (`tests/`) | Yes (`tests/smoke_release.sh`) |
| GitHub Actions CI | Yes (`.github/workflows/ci.yml`) |
| Versioned GitHub Releases + CHANGELOG | Yes |
| Secret scanning (GitHub) | Yes on public repo settings |

## For evaluators

1. Read [SECURITY.md](../SECURITY.md)  
2. From a clean clone: `bash tests/smoke_release.sh`  
3. Skim `skills/computer/scripts/` — no network exfil helpers  
4. Pilot with `TCU_SAFE_MODE=1` and `--dry-run` first  
