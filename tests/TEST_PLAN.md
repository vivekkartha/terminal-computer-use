# Test plan — Terminal Computer Use

Executed by automation / release smoke. IDs map to `tests/run_test_plan.sh`.

| ID | Area | Steps | Pass criteria |
|----|------|-------|---------------|
| T01 | Bootstrap paths | Resolve skill root from install locations | SKILL.md found |
| T02 | Doctor | `doctor.sh` | exit 0, reports version |
| T03 | Help surface | every script `--help` | exit 0 |
| T03b | Capability surface | `test_capability_surface.sh` | open URL + clipboard; browser automation scripts absent; docs refuse browser CU |
| T04 | Organize dry-run | fixture + `--dry-run` | no moves, plan printed |
| T05 | Organize apply | smart organize fixture | categories created |
| T06 | Organize idempotent | re-run organize | nothing to do / exit 0 |
| T07 | Move spaces | move `file with spaces.txt` | dest exists, src gone |
| T08 | Copy spaces | copy spaced file | both exist |
| T09 | SAFE_MODE | `TCU_SAFE_MODE=1` move | no move, dry-run log |
| T10 | Refuse HOME | trash `$HOME` | non-zero, refusing |
| T11 | Trash dry-run | trash file dry-run | file still exists |
| T12 | Clipboard | set/get roundtrip | value matches |
| T13 | Notify | notify test | exit 0 (or skip headless) |
| T14 | Desktop path | desktop-path.sh | path exists or standard location |
| T15 | Install dry-run | `install.sh --dry-run` | exit 0, lists targets |
| T16 | Install unmanaged | project install on dirty dir | skip, NOTES preserved, exit 1 |
| T17 | Demo | demo-organize.sh | exit 0 |
| T18 | Agent prompt file | AGENT_PROMPT.md present | contains bootstrap text |
| T19 | Release smoke | smoke_release.sh | ALL PASSED |
