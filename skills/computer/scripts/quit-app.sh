#!/usr/bin/env bash
# purpose: quit an application by name (graceful, optional force)
# usage: quit-app.sh [--force] <AppName> [...]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: quit-app.sh [--force] <AppName> [...]

Gracefully quit apps. --force uses exact process-name match only
(never substring pkill).

Examples:
  quit-app.sh Spotify
  quit-app.sh "Google Chrome"
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

for app in "${APPS[@]}"; do
  if $FORCE; then
    if tcu_force_quit_app "$app"; then
      log "force-quit: $app"
    else
      log "warn: could not force-quit: $app"
    fi
  else
    if tcu_quit_app "$app"; then
      log "quit: $app"
    else
      log "warn: could not quit (not running, denied, or unsupported OS): $app"
    fi
  fi
done
