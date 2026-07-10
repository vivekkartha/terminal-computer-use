#!/usr/bin/env bash
# purpose: get or set the system clipboard (macOS/Linux)
# usage: clipboard.sh get | clipboard.sh set [text] | clipboard.sh set --file PATH
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: clipboard.sh get
       clipboard.sh set <text...>
       clipboard.sh set --file <path>
       clipboard.sh clear

get  — print clipboard to stdout
set  — set clipboard from args or --file
clear — empty clipboard
EOF
  exit "${1:-0}"
}

[[ $# -ge 1 ]] || usage 1
cmd="$1"; shift

case "$cmd" in
  -h|--help) usage 0 ;;
  get)
    tcu_clipboard_get || die "clipboard get failed (install pbcopy, wl-paste, or xclip)"
    ;;
  clear)
    printf '' | tcu_clipboard_set || die "clipboard clear failed"
    log "clipboard cleared"
    ;;
  set)
    if [[ "${1:-}" == "--file" ]]; then
      [[ $# -ge 2 ]] || die "set --file requires a path"
      f="$2"
      [[ "$f" == ~* ]] && f="${f/#\~/$HOME}"
      [[ -f "$f" ]] || die "not a file: $f"
      tcu_clipboard_set <"$f" || die "clipboard set failed"
      log "clipboard set from file: $f"
    else
      [[ $# -ge 1 ]] || die "set requires text or --file"
      printf '%s' "$*" | tcu_clipboard_set || die "clipboard set failed"
      log "clipboard set"
    fi
    ;;
  *)
    die "unknown command: $cmd (use get|set|clear)"
    ;;
esac
