#!/usr/bin/env bash
# purpose: bring an application to the foreground (launch if needed)
# usage: app-activate.sh <AppName>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: app-activate.sh <AppName>

Launch (if needed) and activate the named application.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0
[[ $# -ge 1 ]] || usage 1
APP="$*"

tcu_activate_app "$APP" || die "failed to activate: $APP (unsupported OS or missing tools)"
log "activated: $APP"
