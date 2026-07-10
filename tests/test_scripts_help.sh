#!/usr/bin/env bash
# Every top-level script must accept --help and exit 0.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="${ROOT}/skills/computer/scripts"
fail=0

echo "Testing --help on scripts in $SCRIPTS"

while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  [[ "$base" == "lib" ]] && continue
  if [[ "$f" == *.py ]]; then
    if ! python3 "$f" --help >/dev/null 2>&1; then
      echo "FAIL: $base --help"
      fail=$((fail + 1))
    else
      echo "OK   $base"
    fi
  else
    if ! bash "$f" --help >/dev/null 2>&1; then
      echo "FAIL: $base --help"
      fail=$((fail + 1))
    else
      echo "OK   $base"
    fi
  fi
done < <(find "$SCRIPTS" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -print0 | sort -z)

if [[ "$fail" -ne 0 ]]; then
  echo "FAILED: $fail script(s)"
  exit 1
fi
echo "All help checks passed."
