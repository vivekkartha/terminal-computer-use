#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(bash "${ROOT}/install.sh" --dry-run 2>&1)"
echo "$out" | grep -q "dry-run\|install" || { echo "FAIL: expected dry-run output"; echo "$out"; exit 1; }
echo "$out" | grep -q "skills/computer\|source:" || { echo "FAIL: expected skill path"; echo "$out"; exit 1; }

FAKE="$(mktemp -d "${TMPDIR:-/tmp}/tcu-inst-XXXXXX")"
trap 'rm -rf "$FAKE" "$PROJ"' EXIT
PROJ="$(mktemp -d "${TMPDIR:-/tmp}/tcu-proj-XXXXXX")"
mkdir -p "$PROJ/.agents/skills/computer"
echo 'mine' > "$PROJ/.agents/skills/computer/NOTES.md"

(
  cd "$PROJ"
  out2="$(bash "${ROOT}/install.sh" --project --dry-run 2>&1 || true)"
  echo "$out2" | grep -q "agents/skills/computer" || { echo "FAIL project dry-run"; echo "$out2"; exit 1; }
  echo "$out2" | grep -qi "unmanaged\|skip" || { echo "FAIL: expected skip/unmanaged in dry-run"; echo "$out2"; exit 1; }
)

# real install without force should skip unmanaged and exit 1 (nothing installed)
set +e
(
  cd "$PROJ"
  bash "${ROOT}/install.sh" --project >"$FAKE/out.txt" 2>&1
  echo $? >"$FAKE/code.txt"
)
set -e
code="$(cat "$FAKE/code.txt")"
[[ "$code" == "1" ]] || { echo "FAIL: expected exit 1 when all skipped, got $code"; cat "$FAKE/out.txt"; exit 1; }
grep -qi 'unmanaged\|nothing installed' "$FAKE/out.txt" || { echo "FAIL: expected skip message"; cat "$FAKE/out.txt"; exit 1; }
[[ -f "$PROJ/.agents/skills/computer/NOTES.md" ]] || { echo "FAIL: notes lost"; exit 1; }
grep -q 'mine' "$PROJ/.agents/skills/computer/NOTES.md" || { echo "FAIL: notes content changed"; exit 1; }

echo "test_install_dry: OK"
