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

if safe_mode && ! $DRY; then
  log "TCU_SAFE_MODE=1 → forcing dry-run (pass after disabling safe mode to execute)"
  DRY=true
fi

for t in "${PATHS[@]}"; do
  p="$t"
  [[ "$p" == ~* ]] && p="${p/#\~/$HOME}"
  [[ -e "$p" ]] || die "not found: $p"
  assert_safe_path "$p"

  if $DRY; then
    log "[dry-run] trash: $p"
    continue
  fi

  case "$TCU_OS" in
    macos)
      if have trash; then
        trash "$p"
      else
        # Finder trash via AppleScript
        abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
        osascript -e "tell application \"Finder\" to delete POSIX file \"${abs}\"" >/dev/null
      fi
      ;;
    linux)
      if have gio; then
        gio trash "$p"
      elif have trash-put; then
        trash-put "$p"
      else
        die "no trash helper (install trash-cli or use gio). refusing rm."
      fi
      ;;
    *)
      die "trash not supported on OS=$TCU_OS"
      ;;
  esac
  log "trashed: $p"
done
