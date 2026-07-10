#!/usr/bin/env bash
# purpose: reveal one or more paths in the file manager
# usage: reveal-in-finder.sh <path> [...]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: reveal-in-finder.sh <path> [...]

Reveal paths in Finder (macOS) or the default file manager (Linux).
EOF
  exit "${1:-0}"
}

[[ $# -gt 0 ]] || usage 1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

for t in "$@"; do
  p="$t"
  [[ "$p" == ~* ]] && p="${p/#\~/$HOME}"
  [[ -e "$p" ]] || die "not found: $p"
  tcu_reveal "$p" || die "reveal failed: $p"
  log "revealed: $p"
done
