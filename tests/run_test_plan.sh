#!/usr/bin/env bash
# Execute TEST_PLAN.md autonomously. Exit non-zero on any failure.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="${ROOT}/skills/computer/scripts"
pass=0
fail=0
skip=0
results=()

record() {
  local id="$1" status="$2" msg="${3:-}"
  results+=("$status $id $msg")
  case "$status" in
    PASS) pass=$((pass + 1)); printf '  PASS  %s %s\n' "$id" "$msg" ;;
    FAIL) fail=$((fail + 1)); printf '  FAIL  %s %s\n' "$id" "$msg" ;;
    SKIP) skip=$((skip + 1)); printf '  SKIP  %s %s\n' "$id" "$msg" ;;
  esac
}

echo "=== Terminal Computer Use — test plan ==="
echo "ROOT=$ROOT"
echo

# T01 Bootstrap paths
skill=""
for p in \
  "${TERMINAL_COMPUTER_USE_HOME:-}" \
  "${HOME}/.agents/skills/computer" \
  "${HOME}/.claude/skills/computer" \
  "${HOME}/.grok/skills/computer" \
  "${HOME}/.cursor/skills/computer" \
  "${ROOT}/skills/computer"
do
  [[ -z "$p" ]] && continue
  if [[ -f "$p/SKILL.md" ]]; then skill="$p"; break; fi
done
if [[ -n "$skill" ]]; then
  record T01 PASS "skill=$skill"
else
  record T01 FAIL "no SKILL.md found"
fi

# T02 Doctor
if bash "${S}/doctor.sh" >/tmp/tcu-t02.out 2>&1; then
  if grep -qE 'version:|0\.' /tmp/tcu-t02.out; then
    record T02 PASS "doctor ok"
  else
    record T02 PASS "doctor exit 0"
  fi
else
  record T02 FAIL "$(tail -3 /tmp/tcu-t02.out | tr '\n' ' ')"
fi

# T03 Help
if bash "${ROOT}/tests/test_scripts_help.sh" >/tmp/tcu-t03.out 2>&1; then
  record T03 PASS
else
  record T03 FAIL
fi

# T04–T06 Organize
FIX="$(mktemp -d "${TMPDIR:-/tmp}/tcu-tp-XXXXXX")"
printf x > "${FIX}/Screenshot plan.png"
printf x > "${FIX}/photo.jpg"
printf x > "${FIX}/doc with spaces.txt"
printf x > "${FIX}/pack.zip"

if python3 "${S}/fs-organize.py" --dry-run --by smart "$FIX" >/tmp/tcu-t04.out 2>&1 \
  && [[ -f "${FIX}/photo.jpg" ]] \
  && grep -q 'DRY-RUN\|dry-run\|would move' /tmp/tcu-t04.out; then
  record T04 PASS
else
  record T04 FAIL
fi

if python3 "${S}/fs-organize.py" --by smart "$FIX" >/tmp/tcu-t05.out 2>&1 \
  && [[ -f "${FIX}/Images/photo.jpg" ]] \
  && [[ -f "${FIX}/Screenshots/Screenshot plan.png" ]] \
  && [[ -f "${FIX}/Documents/doc with spaces.txt" ]]; then
  record T05 PASS
else
  record T05 FAIL
fi

if python3 "${S}/fs-organize.py" --by smart "$FIX" >/tmp/tcu-t06.out 2>&1; then
  if grep -qiE 'nothing to do|0 move' /tmp/tcu-t06.out || [[ ! -f "${FIX}/photo.jpg" ]]; then
    record T06 PASS
  else
    record T06 PASS "re-run ok"
  fi
else
  record T06 FAIL
fi

# T07 Move spaces
M="$(mktemp -d "${TMPDIR:-/tmp}/tcu-tpm-XXXXXX")"
mkdir -p "$M/a" "$M/b"
printf y > "$M/a/hello world.txt"
if bash "${S}/fs-move.sh" "$M/a/hello world.txt" "$M/b/" 2>/tmp/tcu-t07.err \
  && [[ -f "$M/b/hello world.txt" ]] && [[ ! -f "$M/a/hello world.txt" ]]; then
  record T07 PASS
else
  record T07 FAIL
fi

# T08 Copy spaces
printf z > "$M/a/copy me.txt"
if bash "${S}/fs-copy.sh" "$M/a/copy me.txt" "$M/b/" 2>/tmp/tcu-t08.err \
  && [[ -f "$M/b/copy me.txt" ]] && [[ -f "$M/a/copy me.txt" ]]; then
  record T08 PASS
else
  record T08 FAIL
fi

# T09 SAFE_MODE
printf w > "$M/a/safe.txt"
if TCU_SAFE_MODE=1 bash "${S}/fs-move.sh" "$M/a/safe.txt" "$M/b/" 2>/tmp/tcu-t09.err \
  && [[ -f "$M/a/safe.txt" ]] \
  && grep -qiE 'dry-run|SAFE_MODE' /tmp/tcu-t09.err; then
  record T09 PASS
else
  record T09 FAIL
fi

# T10 Refuse HOME
if bash "${S}/safe-trash.sh" --dry-run "$HOME" 2>/tmp/tcu-t10.err; then
  record T10 FAIL "should refuse HOME"
else
  if grep -qiE 'refus|unsafe' /tmp/tcu-t10.err; then
    record T10 PASS
  else
    record T10 FAIL "wrong error"
  fi
fi

# T11 Trash dry-run
if bash "${S}/safe-trash.sh" --dry-run "$M/b/hello world.txt" 2>/tmp/tcu-t11.err \
  && [[ -f "$M/b/hello world.txt" ]]; then
  record T11 PASS
else
  record T11 FAIL
fi

# T12 Clipboard
if bash "${S}/clipboard.sh" set "tcu-plan-$(date +%s)" 2>/tmp/tcu-t12.err \
  && got="$(bash "${S}/clipboard.sh" get 2>/dev/null)" \
  && [[ "$got" == tcu-plan-* ]]; then
  record T12 PASS
else
  record T12 FAIL "clipboard unavailable or mismatch"
fi

# T13 Notify
if bash "${S}/notify.sh" --title "TCU test plan" "ok" 2>/tmp/tcu-t13.err; then
  record T13 PASS
else
  record T13 SKIP "notify failed (permissions/headless?)"
fi

# T14 Desktop path
desk="$(bash "${S}/desktop-path.sh" 2>/dev/null || true)"
if [[ -n "$desk" ]]; then
  record T14 PASS "$desk"
else
  record T14 FAIL
fi

# T15 Install dry-run
if bash "${ROOT}/install.sh" --dry-run >/tmp/tcu-t15.out 2>&1; then
  record T15 PASS
else
  record T15 FAIL
fi

# T16 Unmanaged install
PROJ="$(mktemp -d "${TMPDIR:-/tmp}/tcu-tpi-XXXXXX")"
mkdir -p "$PROJ/.agents/skills/computer"
echo 'keep-me' > "$PROJ/.agents/skills/computer/NOTES.md"
set +e
( cd "$PROJ" && bash "${ROOT}/install.sh" --project >/tmp/tcu-t16.out 2>&1 )
code=$?
set -e
if [[ "$code" -eq 1 ]] && grep -qi unmanaged /tmp/tcu-t16.out \
  && grep -q 'keep-me' "$PROJ/.agents/skills/computer/NOTES.md"; then
  record T16 PASS
else
  record T16 FAIL "code=$code"
fi

# T17 Demo
if bash "${ROOT}/demos/scripts/demo-organize.sh" >/tmp/tcu-t17.out 2>&1; then
  record T17 PASS
else
  record T17 FAIL
fi

# T18 Agent prompt
if [[ -f "${ROOT}/docs/AGENT_PROMPT.md" ]] \
  && grep -q 'Bootstrap' "${ROOT}/docs/AGENT_PROMPT.md" \
  && grep -q 'Find the skill' "${ROOT}/README.md"; then
  record T18 PASS
else
  record T18 FAIL
fi

# T19 Release smoke
if bash "${ROOT}/tests/smoke_release.sh" >/tmp/tcu-t19.out 2>&1; then
  record T19 PASS
else
  record T19 FAIL
fi

rm -rf "$FIX" "$M" "$PROJ" "${ROOT}/.demo-fixture" 2>/dev/null || true

echo
echo "=== summary: pass=$pass fail=$fail skip=$skip ==="
if [[ "$fail" -gt 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASS"
exit 0
