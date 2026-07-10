#!/usr/bin/env bash
# purpose: show a desktop notification (macOS/Linux)
# usage: notify.sh [--title T] [--subtitle S] [--sound NAME] <message>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: notify.sh [--title T] [--subtitle S] [--sound NAME] <message>

Default title: Terminal Computer Use
Sound examples (macOS): default, Glass, Hero, Ping, Purr
EOF
  exit "${1:-0}"
}

TITLE="Terminal Computer Use"
SUBTITLE=""
SOUND=""
MSG_PARTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --title) TITLE="$2"; shift 2 ;;
    --subtitle) SUBTITLE="$2"; shift 2 ;;
    --sound) SOUND="$2"; shift 2 ;;
    *) MSG_PARTS+=("$1"); shift ;;
  esac
done

[[ ${#MSG_PARTS[@]} -gt 0 ]] || usage 1
MSG="${MSG_PARTS[*]}"

tcu_notify "$TITLE" "$MSG" "$SUBTITLE" "$SOUND" || die "notification failed (osascript/notify-send missing?)"
log "notified: $TITLE — $MSG"
