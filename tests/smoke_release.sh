#!/usr/bin/env bash
# Release gate: one command before tagging a public release.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="${ROOT}/skills/computer/scripts"
fail=0

step() { printf '\n==> %s\n' "$*"; }
ok() { printf '    OK %s\n' "$*"; }
bad() { printf '    FAIL %s\n' "$*"; fail=$((fail + 1)); }

step "doctor"
if bash "${S}/doctor.sh" >/tmp/tcu-doctor.out 2>&1; then
  ok "doctor"
else
  bad "doctor"; cat /tmp/tcu-doctor.out
fi

step "help scripts"
if bash "${ROOT}/tests/test_scripts_help.sh" >/tmp/tcu-help.out 2>&1; then
  ok "help"
else
  bad "help"; cat /tmp/tcu-help.out
fi

step "medium-workflow capability surface (browser + gated publish)"
if bash "${ROOT}/tests/test_medium_workflow_capability_surface.sh" >/tmp/tcu-cap.out 2>&1; then
  ok "capability surface"
else
  bad "capability surface"; cat /tmp/tcu-cap.out
fi

step "browser policy unit tests"
if python3 "${ROOT}/tests/test_browser_policy.py" >/tmp/tcu-bpol.out 2>&1; then
  ok "browser policy"
else
  bad "browser policy"; cat /tmp/tcu-bpol.out
fi

step "browser smoke (skip if no playwright/chromium)"
if python3 "${ROOT}/tests/test_browser_smoke.py" >/tmp/tcu-bsmoke.out 2>&1; then
  ok "browser smoke"
else
  bad "browser smoke"; cat /tmp/tcu-bsmoke.out
fi

step "fs-move spaces + safe mode"
if bash "${ROOT}/tests/test_fs_move.sh" >/tmp/tcu-move.out 2>&1; then
  ok "fs-move"
else
  bad "fs-move"; cat /tmp/tcu-move.out
fi

step "fs-organize"
if python3 "${ROOT}/tests/test_fs_smart_organize.py" >/tmp/tcu-org.out 2>&1; then
  ok "fs-organize"
else
  bad "fs-organize"; cat /tmp/tcu-org.out
fi

step "install dry-run + unmanaged"
if bash "${ROOT}/tests/test_install_dry.sh" >/tmp/tcu-inst.out 2>&1; then
  ok "install"
else
  bad "install"; cat /tmp/tcu-inst.out
fi

step "fixture organize + move + trash dry-run"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/tcu-smoke-XXXXXX")"
printf x > "${FIX}/Screenshot smoke.png"
printf x > "${FIX}/file with spaces.txt"
printf x > "${FIX}/pic.jpg"
if python3 "${S}/fs-organize.py" --dry-run --by smart "$FIX" >/tmp/tcu-fix-dry.out 2>&1 \
  && python3 "${S}/fs-organize.py" --by smart "$FIX" >/tmp/tcu-fix.out 2>&1 \
  && [[ -f "${FIX}/Screenshots/Screenshot smoke.png" ]] \
  && [[ -f "${FIX}/Images/pic.jpg" ]]; then
  ok "organize fixture"
else
  bad "organize fixture"; cat /tmp/tcu-fix.out 2>/dev/null || true
fi

M="$(mktemp -d "${TMPDIR:-/tmp}/tcu-smoke-m-XXXXXX")"
mkdir -p "$M/in" "$M/out"
printf y > "$M/in/hello world.txt"
if bash "${S}/fs-move.sh" "$M/in/hello world.txt" "$M/out/" 2>/tmp/tcu-m.err \
  && [[ -f "$M/out/hello world.txt" ]]; then
  ok "move spaced path"
else
  bad "move spaced path"; cat /tmp/tcu-m.err
fi

if bash "${S}/safe-trash.sh" --dry-run "$M/out/hello world.txt" 2>/tmp/tcu-tr.err; then
  ok "trash dry-run"
else
  bad "trash dry-run"; cat /tmp/tcu-tr.err
fi

if bash "${S}/safe-trash.sh" --dry-run "$HOME" 2>/tmp/tcu-home.err; then
  bad "should refuse trashing HOME"
else
  ok "refuse HOME"
fi

step "install.sh --dry-run"
if bash "${ROOT}/install.sh" --dry-run >/tmp/tcu-idry.out 2>&1; then
  ok "install dry-run"
else
  bad "install dry-run"; cat /tmp/tcu-idry.out
fi

step "demo script"
if bash "${ROOT}/demos/scripts/demo-organize.sh" >/tmp/tcu-demo.out 2>&1; then
  ok "demo-organize"
else
  bad "demo-organize"; cat /tmp/tcu-demo.out
fi

rm -rf "$FIX" "$M" "${ROOT}/.demo-fixture" 2>/dev/null || true

echo
if [[ "$fail" -eq 0 ]]; then
  echo "smoke_release: ALL PASSED"
  exit 0
fi
echo "smoke_release: $fail failure(s)"
exit 1
