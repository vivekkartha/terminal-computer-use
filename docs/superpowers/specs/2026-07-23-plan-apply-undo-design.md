# Design: Plan / Apply / Undo for bulk file ops

**Status:** implemented (organize v1) + restructure: plan-before-move, single `run_moves`, post-op receipt  
**Date:** 2026-07-23  
**Repo:** terminal-computer-use  
**Goal:** Users (and agents) can reverse bulk Desktop/Downloads changes so computer-use stays trusted after the first scary organize.

---

## Problem

Bulk ops (`fs-organize`, later `fs-move`) can rearrange many files. Dry-run and `TCU_SAFE_MODE` prevent accidents only if the agent uses them. Once execute runs, there is no first-class reverse path. Users stop trusting the skill; agents cannot recover from a bad plan.

## Success criteria

1. After an organize **execute**, a single undo restores files to prior paths when safe.
2. Agents can work in two phases: **plan** (no moves) → **apply plan** (moves only listed pairs).
3. Undo refuses silently destructive cases (dest missing, src occupied by different file) with a clear error; partial undo reports what failed.
4. `TCU_SAFE_MODE=1` still forces plan-only / dry-run; never applies or undoes under safe mode unless we explicitly document that undo is also blocked (see below).
5. Existing CLI for organize keeps working: bare execute without plan file still moves (and writes last-plan for undo).
6. Tests cover plan no-move, apply moves, undo restores, refuse bad undo, SAFE_MODE.

## Non-goals

- Windows support
- Vision / screenshots
- Content-aware “AI organize”
- Infinite history / multi-level undo stack beyond “last plan”
- Undo for `safe-trash` (Trash is the recovery path)
- New task recipes (find-latest, quit-all-but, etc.)

---

## Product behavior

### Mental model

```
plan  →  list of moves, no filesystem mutation (except writing plan JSON)
apply →  execute exactly those moves
undo  →  reverse last successful apply (or last execute that recorded a plan)
```

Default “organize my desktop” path for agents:

1. Plan (or dry-run) and show summary  
2. Apply if user wants / plan looks right  
3. If wrong: undo  

### Commands (organize — phase 1)

Extend `fs-organize.py`:

| Invocation | Behavior |
|------------|----------|
| `fs-organize.py [--by …] DIR` | Build plan, **execute** moves, write plan (`status: applied`), print receipt |
| `fs-organize.py --dry-run [--by …] DIR` | Build plan, **no moves**, write plan (`status: planned`), print receipt |
| `fs-organize.py --plan PATH … DIR` | Same as above, but also write a copy of the plan to `PATH` (in addition to the default last-plan path) |
| `fs-organize.py --apply [PATH]` | No directory scan. Execute moves from plan file only (`PATH` or default last-plan) |
| `fs-organize.py --undo [PATH]` | Reverse moves from plan file (`PATH` or default last-plan) |

**Mode resolution (explicit):**

- Exactly one of: **scan mode** (source dir present), **`--apply`**, or **`--undo`**. Combining apply/undo with a source dir is an error.
- Scan mode always refreshes the default last-plan file after a successful plan build (`planned` if dry-run/SAFE_MODE, `applied` if moves ran).
- `--plan PATH` only adds an extra write destination; it does not change whether moves run.
- `TCU_SAFE_MODE=1` in scan mode forces dry-run (no moves). `TCU_SAFE_MODE=1` with `--apply` or `--undo` **exits non-zero** and does not mutate (safe mode means no mutations at all).

### Default plan location

```
${TCU_STATE_DIR:-$HOME/.tcu}/last-organize-plan.json
```

- Create `$HOME/.tcu` with mode `0700` when writing.
- Override: `TCU_STATE_DIR`, or explicit `--plan` / `--apply` / `--undo` path.

### Plan file schema (JSON)

```json
{
  "version": 1,
  "kind": "organize",
  "created_at": "ISO-8601",
  "status": "planned | applied | undone | failed",
  "by": "smart | extension | date",
  "source": "/abs/path",
  "dest_root": "/abs/path",
  "moves": [
    {
      "from": "/abs/src/file",
      "to": "/abs/dest/file",
      "category": "Images"
    }
  ],
  "meta": {
    "hostname": "optional",
    "tool_version": "from VERSION if available"
  }
}
```

Rules:

- Paths are absolute and resolved at plan time.
- `moves` order is apply order; undo runs **reverse** order.
- No secrets; plan may list personal filenames — state dir is user-local `0700`.

### Apply semantics

For each move in order:

1. If `from` missing and `to` already exists with same basename intent → treat as already applied (idempotent skip).
2. If `from` missing and `to` missing → fail that item.
3. If `to` exists and is a different file → fail that item (no overwrite).
4. Else `mkdir -p` parent of `to`, `shutil.move(from, to)`.

After loop:

- If all ok → `status: applied`, rewrite plan file.
- If any fail → `status: failed`, include `errors: [{from, to, reason}]`, non-zero exit. Successful moves stay applied (no auto-rollback of partial apply). User may `--undo` only if we document partial undo: **undo reverses only pairs where `to` exists and `from` does not** (best-effort reverse of applied subset).

### Undo semantics

Preconditions:

- Plan `status` is `applied` or `failed` (partial).
- For each move in reverse order: if `to` exists and `from` does not exist → move `to` → `from` (create parent). If both exist → skip with error. If neither → skip. If only `from` exists → already undone, skip.

After:

- If all reversible items ok → `status: undone`.
- Else non-zero + remaining errors; leave status `failed` or `applied` with error list.

Refuse undo when plan `kind` is not `organize` (forward-compat).

### Receipt (stdout)

Human-readable summary always:

```
source: …
dest:   …
by:     …
mode:   PLAN | APPLY | EXECUTE | UNDO | DRY-RUN
plan:   N move(s)
status: …
plan_file: /path/to/last-organize-plan.json
```

Agents parse plan file for machine detail; no requirement for JSON on stdout in v1.

---

## Architecture

### Components

| Unit | Responsibility |
|------|----------------|
| `fs-organize.py` | CLI flags, plan build, apply, undo, SAFE_MODE |
| Optional tiny helper module in same file or `scripts/lib/plan_io.py` | load/save plan, schema validation — only if file grows unwieldy; prefer keep in one file if &lt; ~350 lines |
| Default state dir | `~/.tcu` via env |
| Tests | `tests/test_fs_smart_organize.py` extended + plan/undo cases |

### Data flow

```
scan source dir → moves[] → write plan (planned)
                         ↘ execute moves → write plan (applied)
apply plan file → moves[] → execute → write plan (applied)
undo plan file  → reverse moves → write plan (undone)
```

### fs-move (phase 2 — same design, later PR if needed)

Out of critical path for first ship, but interface reserved:

- Same schema with `kind: "move"`.
- Default file: `last-move-plan.json` or unified `last-plan.json` with kind field.
- **v1 ships organize only.** Move follows once organize path is proven.

---

## Error handling

| Case | Exit | Message |
|------|------|---------|
| SAFE_MODE + apply/undo | 1 | `TCU_SAFE_MODE=1 blocks apply/undo` |
| Plan missing / bad JSON | 1 | clear path error |
| Plan version unsupported | 1 | version mismatch |
| Source is HOME or `/` | 1 | existing refuse |
| Partial apply/undo | 1 | list failed pairs on stderr; plan has `errors` |
| Empty plan | 0 | nothing to do |

---

## Safety

- Reuse existing refuse of organizing `$HOME` and `/`.
- Apply does not take a free-form shell; only paths inside plan JSON.
- Plan write uses user state dir, not world-writable temp, for default path.
- No network.
- Undo never `rm`; only moves files back.

---

## Testing

Extend `tests/test_fs_smart_organize.py` (or sibling `test_fs_organize_plan.py`):

| ID | Case |
|----|------|
| P1 | `--dry-run` writes default plan, files unmoved |
| P2 | execute moves + plan status `applied` |
| P3 | `--undo` restores files to original paths |
| P4 | `--apply` from plan after dry-run |
| P5 | SAFE_MODE blocks apply and undo |
| P6 | undo fails cleanly if dest file deleted |
| P7 | existing smart/extension/home-refuse tests still pass |

Include in `smoke_release.sh` if cheap (one plan→apply→undo fixture).

---

## Docs / skill surface

- `SKILL.md` capability map: plan / apply / undo one-liners.
- `AGENT_PROMPT.md`: bulk file ops → dry-run/plan first; undo if wrong.
- `references/safety.md`: undo recovers last organize; not a substitute for trash caution.
- `CHANGELOG` unreleased section.
- README safety bullet: undo last organize via `--undo`.

---

## Rollout

1. Implement organize plan/apply/undo + tests.  
2. Docs/skill only after tests green.  
3. No version bump required for unreleased; bump to 0.3.0 when releasing this feature.

---

## Open decisions (resolved in this spec)

| Topic | Decision |
|-------|----------|
| Dry-run writes default plan? | **Yes** — status `planned` |
| SAFE_MODE and undo? | **Block** apply and undo |
| Partial apply auto-rollback? | **No** — best-effort undo afterward |
| Multi-level undo? | **No** — last plan only |
| fs-move in same PR? | **No** — organize only |

---

## Implementation sketch (non-binding order)

1. Plan schema + load/save helpers  
2. Wire write-plan into dry-run and execute paths  
3. `--apply` / `--undo` CLI  
4. SAFE_MODE gates  
5. Tests P1–P7  
6. Docs  
