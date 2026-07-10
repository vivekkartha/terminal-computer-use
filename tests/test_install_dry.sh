#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(bash "${ROOT}/install.sh" --dry-run 2>&1)"
echo "$out" | grep -q "dry-run\|install" || { echo "FAIL: expected dry-run output"; echo "$out"; exit 1; }
echo "$out" | grep -q "skills/computer\|source:" || { echo "FAIL: expected skill path"; echo "$out"; exit 1; }

# unmanaged refuse: create fake dest without marker
FAKE="$(mktemp -d "${TMPDIR:-/tmp}/tcu-inst-XXXXXX")"
trap 'rm -rf "$FAKE"' EXIT
mkdir -p "$FAKE/skills/computer"
echo 'user notes' > "$FAKE/skills/computer/NOTES.md"

# Simulate by installing to a custom path via HOME override is hard;
# unit-test is_managed logic via running install --project in a temp project
PROJ="$(mktemp -d "${TMPDIR:-/tmp}/tcu-proj-XXXXXX")"
mkdir -p "$PROJ/.agents/skills/computer"
echo 'mine' > "$PROJ/.agents/skills/computer/NOTES.md"
(
  cd "$PROJ"
  out2="$(bash "${ROOT}/install.sh" --project --dry-run 2>&1)"
  echo "$out2" | grep -q "agents/skills/computer" || { echo "FAIL project dry-run"; echo "$out2"; exit 1; }
)
# real install without force should skip unmanaged
(
  cd "$PROJ"
  bash "${ROOT}/install.sh" --project 2>&1 | tee "$FAKE/out.txt"
  grep -q 'skip (unmanaged' "$FAKE/out.txt" || grep -q 'unmanaged' "$FAKE/out.txt" || {
    # if it installed with force-less and wiped, NOTES gone = fail
    if [[ ! -f "$PROJ/.agents/skills/computer/NOTES.md" ]]; then
      echo "FAIL: wiped unmanaged NOTES.md"
      exit 1
    fi
  }
  [[ -f "$PROJ/.agents/skills/computer/NOTES.md" ]] || { echo FAIL: notes lost; exit 1; }
)

echo "test_install_dry: OK"
