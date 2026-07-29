# Growth playbook (solo)

Traffic last ~2 weeks: ~1 unique GitHub viewer, ~26 unique clones (mostly bots/CI). Product works; **distribution is the gap.**

## Positioning (one line)

> Shell desktop control for coding agents — organize files, apps, clipboard — without flaky screenshot computer-use.

## Who buys

| Persona | Hook | Channel |
|---------|------|---------|
| Claude Code power users | “Agent can clean Desktop safely” | r/ClaudeAI, r/ClaudeCode, X #ClaudeCode |
| Cursor / Codex users | “Skill + scripts, not vision CU” | r/cursor, skills.sh, awesome-agent-skills |
| Mac messy-desktop people | Organize dry-run + undo | Show HN, Product Hunt (later) |

## Highest leverage (this week)

1. **Ship a 20s clip** — run `demo-organize.sh`, screen-record, put GIF in README  
2. **Post once** with install one-liner + GIF (template below)  
3. **Reply** under “computer use is flaky / expensive” threads: terminal control plane alternative  
4. **List** on skills.sh / skill marketplaces if not already indexed  
5. **Keep README conversion-first** (install above fold; “not browser” is a footnote, not the headline)

## Do not waste time on

- More features before 50 real installs  
- Browser automation comeback  
- SEO blog farm without a demo artifact  
- Polishing docs no one has opened

## Post templates

### X / Bluesky

```text
Vision “computer use” burns tokens guessing clicks.

I open-sourced Terminal Computer Use: shell scripts your coding agent runs for files, apps, clipboard — with dry-run + undo.

npx skills add vivekkartha/terminal-computer-use -g

Works with Claude Code / Cursor / Codex / Grok.
```

### Reddit (r/ClaudeAI etc.)

```text
Title: Skill: give Claude Code safe desktop control (files/apps) without vision Computer Use

Body:
I got tired of screenshot→click loops for basic desktop chores.

Terminal Computer Use is a SKILL.md + scripts: organize Desktop (plan/apply/undo), open apps, clipboard, notify. macOS first.

Install: npx skills add vivekkartha/terminal-computer-use -g
Demo: bash demos/scripts/demo-organize.sh
Repo: https://github.com/vivekkartha/terminal-computer-use

Not browser automation — captchas win that fight. Happy to take feature requests that fit shell control.
```

### Show HN

```text
Title: Show HN: Terminal Computer Use – desktop automation for coding agents (no vision)
URL: https://github.com/vivekkartha/terminal-computer-use
```

## Metrics that matter

| Metric | Target first |
|--------|----------------|
| GitHub unique visitors / week | >100 |
| Stars | ignore until traffic |
| Real installs (doctor runs, issues, replies) | 10 humans |
| Demo clip views | >1k |

## Repo hygiene

- Description + topics match positioning  
- README: install → demo → why → scope  
- One clear hero workflow (organize desktop)  
- Issues: “good first issue” only if you’ll review
