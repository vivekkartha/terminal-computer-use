# Trust & security signals

This document lists **what this project claims** and **what free, verifiable signals** support that. Nothing here is a paid audit (SOC 2, ISO 27001, etc.).

## What we claim

| Claim | Meaning |
|-------|---------|
| MIT licensed | Free to use, modify, and redistribute under [LICENSE](../LICENSE) |
| No telemetry | Scripts and installer do not phone home or collect analytics |
| Open source | Full source on GitHub; inspect before you run |
| Safe defaults | Mutating ops support `--dry-run`; trash over `rm -rf`; path guards |
| Responsible disclosure | [SECURITY.md](../SECURITY.md) + private vulnerability reporting |

## What we do **not** claim

- Not “enterprise certified” or “guaranteed secure”
- Not a substitute for your org’s agent / endpoint policy
- Not a formal third-party penetration test

By design, this skill can **move files and control apps**. Treat it like shell access for a careful assistant.

## Free signals on this repo

| Signal | Status |
|--------|--------|
| OSI-style permissive license (MIT) | ✅ |
| SECURITY.md + threat model | ✅ |
| Private vulnerability reporting (GitHub) | ✅ (enable in repo Security settings if missing) |
| Dependabot config | ✅ `.github/dependabot.yml` |
| Automated tests + `smoke_release.sh` | ✅ |
| Versioned releases + CHANGELOG | ✅ |
| Secret scanning (GitHub public) | ✅ when enabled on the repo |
| OpenSSF Scorecard Action | ⬜ needs `workflow` scope to push CI (see below) |
| OpenSSF Best Practices Badge | ⬜ free self-cert at [bestpractices.dev](https://www.bestpractices.dev) — repo criteria mostly met |

## Optional next steps (maintainer, ~15 min)

1. **OpenSSF Best Practices (Passing)**  
   Create a project at https://www.bestpractices.dev/en/projects/new pointing at this repo.  
   Many “Passing” answers are already true (license, docs, tests, SECURITY.md, releases).

2. **Scorecard + CI badge**  
   ```bash
   gh auth refresh -h github.com -s workflow
   git add .github/workflows/
   git commit -m "ci: scorecard + tests"
   git push
   ```

3. Keep **Dependabot** PRs merged when Actions/npm updates appear.

## For enterprise evaluators

Recommended review path:

1. Read [SECURITY.md](../SECURITY.md) (threat model)  
2. Run `bash tests/smoke_release.sh` from a clean clone  
3. Inspect `skills/computer/scripts/` — no network exfil helpers  
4. Pilot with `TCU_SAFE_MODE=1` and `--dry-run` first  
