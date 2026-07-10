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

List running applications (one name per line, or JSON array).
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

raw="$(tcu_list_apps)" || die "list-apps failed (unsupported OS or missing tools)"
# trim empty lines
raw="$(printf '%s\n' "$raw" | sed '/^$/d')"

if $JSON; then
  printf '%s\n' "$raw" | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()], indent=2))'
else
  printf '%s\n' "$raw" | sort -f
fi
