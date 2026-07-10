#!/usr/bin/env bash
# Bash 3.2 + paths-with-spaces tests for fs-move / fs-copy
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOVE="${ROOT}/skills/computer/scripts/fs-move.sh"
COPY="${ROOT}/skills/computer/scripts/fs-copy.sh"
BASH_BIN="${BASH_BIN:-/bin/bash}"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/tcu-fs-XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

mkdir -p "$TMP/src" "$TMP/out"
printf 'hello' > "$TMP/src/file with spaces.txt"
printf 'a' > "$TMP/src/a.txt"
printf 'b' > "$TMP/src/b.txt"

echo "== dry-run move with spaces =="
"$BASH_BIN" "$MOVE" --dry-run "$TMP/src/file with spaces.txt" "$TMP/out/"
[[ -f "$TMP/src/file with spaces.txt" ]] || { echo FAIL: dry-run removed source; exit 1; }

echo "== execute move with spaces =="
"$BASH_BIN" "$MOVE" "$TMP/src/file with spaces.txt" "$TMP/out/"
[[ -f "$TMP/out/file with spaces.txt" ]] || { echo FAIL: space file not moved; exit 1; }
[[ ! -f "$TMP/src/file with spaces.txt" ]] || { echo FAIL: source still present; exit 1; }

echo "== multi move =="
"$BASH_BIN" "$MOVE" "$TMP/src/a.txt" "$TMP/src/b.txt" "$TMP/out/"
[[ -f "$TMP/out/a.txt" && -f "$TMP/out/b.txt" ]] || { echo FAIL: multi move; exit 1; }

echo "== copy with spaces =="
printf 'c' > "$TMP/src/copy me.txt"
"$BASH_BIN" "$COPY" "$TMP/src/copy me.txt" "$TMP/out/"
[[ -f "$TMP/out/copy me.txt" && -f "$TMP/src/copy me.txt" ]] || { echo FAIL: copy; exit 1; }

echo "== safe mode forces dry-run =="
printf 'x' > "$TMP/src/safe.txt"
TCU_SAFE_MODE=1 "$BASH_BIN" "$MOVE" "$TMP/src/safe.txt" "$TMP/out/" 2>"$TMP/safe.err"
[[ -f "$TMP/src/safe.txt" ]] || { echo FAIL: safe mode moved file; exit 1; }
grep -q 'dry-run\|SAFE_MODE' "$TMP/safe.err" || { echo FAIL: expected safe mode message; cat "$TMP/safe.err"; exit 1; }

echo "== refuse home =="
if "$BASH_BIN" "$MOVE" --dry-run "$TMP/out/a.txt" "$HOME" 2>"$TMP/home.err"; then
  # dry-run still validates dest via assert_safe_path
  :
fi
# moving INTO home as dest file rename of home is refused; dest=$HOME as dir might allow
# assert_safe_path on $HOME should die
if "$BASH_BIN" "${ROOT}/skills/computer/scripts/safe-trash.sh" --dry-run "$HOME" 2>"$TMP/trash.err"; then
  echo FAIL: trash home should fail; exit 1
fi
grep -qi 'refusing\|unsafe' "$TMP/trash.err" || { echo FAIL: expected refuse message; cat "$TMP/trash.err"; exit 1; }

echo "test_fs_move: OK"
