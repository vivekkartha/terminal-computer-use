#!/usr/bin/env bash
# purpose: move files/dirs with optional dry-run and mkdir -p for dest
# usage: fs-move.sh [--dry-run] <src> [...] <dest-dir-or-file>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: fs-move.sh [--dry-run] <src> [...] <dest>

Move sources into dest (directory) or rename to dest (single src → path).
Creates parent directories as needed.

Examples:
  fs-move.sh --dry-run ~/Desktop/*.pdf ~/Documents/PDFs/
  fs-move.sh report.txt ~/Archive/report-final.txt
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

if [[ "$DEST" == ~* ]]; then DEST="${DEST/#\~/$HOME}"; fi

# Expand sources
EXPANDED=()
for s in "${SRCS[@]}"; do
  if [[ "$s" == ~* ]]; then s="${s/#\~/$HOME}"; fi
  # shellcheck disable=SC2206
  matches=($s)
  for m in "${matches[@]}"; do
    [[ -e "$m" ]] || die "source not found: $m"
    EXPANDED+=("$m")
  done
done

# If multiple sources, dest must be directory (or will become one)
if [[ ${#EXPANDED[@]} -gt 1 ]]; then
  if [[ -e "$DEST" && ! -d "$DEST" ]]; then
    die "dest must be a directory when moving multiple sources: $DEST"
  fi
  if $DRY; then
    log "[dry-run] mkdir -p $DEST"
  else
    mkdir -p "$DEST"
  fi
  for s in "${EXPANDED[@]}"; do
    base="$(basename "$s")"
    target="${DEST%/}/$base"
    if $DRY; then
      log "[dry-run] mv $s → $target"
    else
      mv "$s" "$target"
      log "moved: $s → $target"
    fi
  done
else
  s="${EXPANDED[0]}"
  if [[ -d "$DEST" || "$DEST" == */ ]]; then
    mkdir -p "${DEST%/}"
    target="${DEST%/}/$(basename "$s")"
  else
    ensure_parent "$DEST"
    target="$DEST"
  fi
  if $DRY; then
    log "[dry-run] mv $s → $target"
  else
    if [[ -d "$DEST" || "$DEST" == */ ]]; then
      mkdir -p "${DEST%/}"
    else
      ensure_parent "$target"
    fi
    mv "$s" "$target"
    log "moved: $s → $target"
  fi
fi
