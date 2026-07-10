#!/usr/bin/env bash
# Create a fixture dir and run smart-organize (safe demo).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/skills/computer/scripts/fs-smart-organize.py"
FIX="${ROOT}/.demo-fixture"
rm -rf "$FIX"
mkdir -p "$FIX"
echo png > "$FIX/Screenshot 2026-01-01 at 10.00.00 AM.png"
echo jpg > "$FIX/receipt.jpg"
echo pdf > "$FIX/invoice.pdf"
echo zip > "$FIX/bundle.zip"
echo "=== before ==="
ls -la "$FIX"
echo "=== dry-run ==="
python3 "$SCRIPT" --dry-run "$FIX"
echo "=== execute ==="
python3 "$SCRIPT" "$FIX"
echo "=== after ==="
find "$FIX" -type f | sort
