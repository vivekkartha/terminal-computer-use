#!/usr/bin/env bash
# purpose: print the frontmost (focused) application name
# usage: frontmost-app.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: frontmost-app.sh

Print the name of the frontmost GUI application.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0
require_cmd osascript

osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'
