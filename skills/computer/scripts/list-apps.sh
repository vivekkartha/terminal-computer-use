#!/usr/bin/env bash
# purpose: list running GUI applications (name per line)
# usage: list-apps.sh [--json]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: list-apps.sh [--json]

List running applications (visible GUI apps via System Events).
EOF
  exit "${1:-0}"
}

JSON=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --json) JSON=true; shift ;;
    *) die "unknown arg: $1" ;;
  esac
done

require_cmd osascript

if $JSON; then
  osascript -e 'tell application "System Events" to get name of every process whose background only is false' \
    | python3 -c 'import sys,json; names=[n.strip() for n in sys.stdin.read().split(",") if n.strip()]; print(json.dumps(names, indent=2))'
else
  osascript -e 'tell application "System Events" to get name of every process whose background only is false' \
    | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort -f
fi
