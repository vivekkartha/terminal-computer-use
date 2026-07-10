#!/usr/bin/env bash
# purpose: move files/dirs to Trash (not permanent delete)
# usage: safe-trash.sh [--dry-run] <path> [...]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: safe-trash.sh [--dry-run] <path> [...]

Move paths to the system Trash / Wastebasket. Never uses rm -rf.
Respects TCU_SAFE_MODE=1 (forces dry-run).
EOF
  exit "${1:-0}"
}

DRY=false
PATHS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --dry-run) DRY=true; shift ;;
    *) PATHS+=("$1"); shift ;;
  esac
done

[[ ${#PATHS[@]} -gt 0 ]] || usage 1
DRY="$(apply_safe_mode "$DRY")"

for t in "${PATHS[@]}"; do
  p="$(expand_user "$t")"
  [[ -e "$p" ]] || die "not found: $p"
  assert_safe_path "$p"

  if [[ "$DRY" == "true" ]]; then
    log "[dry-run] trash: $p"
    continue
  fi

  tcu_trash "$p" || die "trash failed for: $p (install trash-cli/gio on Linux)"
  log "trashed: $p"
done
