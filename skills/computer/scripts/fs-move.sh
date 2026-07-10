#!/usr/bin/env bash
# purpose: move files/dirs with optional dry-run
# usage: fs-move.sh [--dry-run] <src> [...] <dest>
# note: paths are literal (spaces OK). Expand globs in the shell before calling.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/fs.sh
source "${SCRIPT_DIR}/lib/fs.sh"

usage() {
  cat <<'EOF'
usage: fs-move.sh [--dry-run] <src> [...] <dest>

Move sources into dest (directory) or rename to dest (single src → path).
Paths may contain spaces. Expand globs in your shell first:
  fs-move.sh --dry-run ~/Desktop/*.pdf ~/Documents/PDFs/

Respects TCU_SAFE_MODE=1 (forces dry-run).
EOF
  exit "${1:-0}"
}

rc=0
fs_parse_move_args "$@" || rc=$?
[[ $rc -eq 2 ]] && usage 0
[[ $rc -eq 0 ]] || usage 1

fs_run_batch mv "$FS_DRY" "${FS_SRCS[@]}" -- "$FS_DEST"
