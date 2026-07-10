#!/usr/bin/env bash
# purpose: run AppleScript from string or file
# usage: osascript-run.sh -e 'script' | osascript-run.sh -f file.applescript
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: osascript-run.sh -e '<applescript>'
       osascript-run.sh -f <file.applescript>

Thin wrapper around osascript with clearer errors.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0
require_cmd osascript
[[ $# -ge 2 ]] || usage 1

case "$1" in
  -e)
    shift
    osascript -e "$*"
    ;;
  -f)
    f="$2"
    [[ "$f" == ~* ]] && f="${f/#\~/$HOME}"
    [[ -f "$f" ]] || die "not a file: $f"
    osascript "$f"
    ;;
  *)
    usage 1
    ;;
esac
