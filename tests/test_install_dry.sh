#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(bash "${ROOT}/install.sh" --dry-run 2>&1)"
echo "$out" | grep -q "dry-run" || { echo "FAIL: expected dry-run output"; exit 1; }
echo "$out" | grep -q "skills/computer" || { echo "FAIL: expected skill path"; exit 1; }
echo "test_install_dry: OK"
