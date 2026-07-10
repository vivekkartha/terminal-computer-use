#!/usr/bin/env bash
# purpose: copy files/dirs with optional dry-run
# usage: fs-copy.sh [--dry-run] <src> [...] <dest>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: fs-copy.sh [--dry-run] <src> [...] <dest>

Copy sources to dest. Uses cp -R for directories.
EOF
  exit "${1:-0}"
}

DRY=false
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --dry-run) DRY=true; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

[[ ${#ARGS[@]} -ge 2 ]] || usage 1
DEST="${ARGS[-1]}"
SRCS=("${ARGS[@]:0:${#ARGS[@]}-1}")
[[ "$DEST" == ~* ]] && DEST="${DEST/#\~/$HOME}"

EXPANDED=()
for s in "${SRCS[@]}"; do
  [[ "$s" == ~* ]] && s="${s/#\~/$HOME}"
  # shellcheck disable=SC2206
  matches=($s)
  for m in "${matches[@]}"; do
    [[ -e "$m" ]] || die "source not found: $m"
    EXPANDED+=("$m")
  done
done

if [[ ${#EXPANDED[@]} -gt 1 ]]; then
  [[ -e "$DEST" && ! -d "$DEST" ]] && die "dest must be directory for multiple sources"
  $DRY && log "[dry-run] mkdir -p $DEST" || mkdir -p "$DEST"
fi

for s in "${EXPANDED[@]}"; do
  if [[ ${#EXPANDED[@]} -gt 1 || -d "$DEST" ]]; then
    $DRY || mkdir -p "$DEST"
    target="${DEST%/}/$(basename "$s")"
  else
    target="$DEST"
    $DRY || ensure_parent "$target"
  fi
  if $DRY; then
    log "[dry-run] cp -R $s → $target"
  else
    cp -R "$s" "$target"
    log "copied: $s → $target"
  fi
done
