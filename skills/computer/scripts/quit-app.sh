#!/usr/bin/env bash
# purpose: quit a macOS application by name (graceful, optional force)
# usage: quit-app.sh [--force] <AppName> [...]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: quit-app.sh [--force] <AppName> [...]

Gracefully quit apps via AppleScript. Use --force only if hung (kill).

Examples:
  quit-app.sh Spotify
  quit-app.sh "Google Chrome"
  quit-app.sh --force SomeHungApp
EOF
  exit "${1:-0}"
}

FORCE=false
APPS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --force) FORCE=true; shift ;;
    -*) die "unknown flag: $1" ;;
    *) APPS+=("$1"); shift ;;
  esac
done

[[ ${#APPS[@]} -gt 0 ]] || usage 1
require_cmd osascript

for app in "${APPS[@]}"; do
  if $FORCE; then
    # Prefer process name kill; falls back to osascript
    if pgrep -ifx "$app" >/dev/null 2>&1 || pgrep -i "$app" >/dev/null 2>&1; then
      pkill -i "$app" 2>/dev/null || true
      log "force-quit signal sent: $app"
    else
      log "no matching process for force-quit: $app"
    fi
  else
    osascript -e "tell application \"${app}\" to quit" 2>/dev/null \
      && log "quit: $app" \
      || log "warn: could not quit (not running or denied): $app"
  fi
done
