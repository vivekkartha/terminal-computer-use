#!/usr/bin/env bash
# purpose: native macOS file/folder chooser; prints chosen path(s)
# usage: choose-path.sh [--folders|--files] [--multiple] [--prompt TEXT]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: choose-path.sh [--folders|--files] [--multiple] [--prompt TEXT]

Opens a native picker. Prints POSIX paths, one per line.
EOF
  exit "${1:-0}"
}

KIND="files" # files | folders
MULTI=false
PROMPT="Choose"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --folders|--folder) KIND="folders"; shift ;;
    --files|--file) KIND="files"; shift ;;
    --multiple) MULTI=true; shift ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    *) die "unknown arg: $1" ;;
  esac
done

require_cmd osascript

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

if [[ "$KIND" == "folders" ]]; then
  TYPE_CLAUSE="of type {\"public.folder\"}"
else
  TYPE_CLAUSE=""
fi

if $MULTI; then
  MULTI_CLAUSE="with multiple selections allowed"
else
  MULTI_CLAUSE=""
fi

# AppleScript choose file/folder
if [[ "$KIND" == "folders" ]]; then
  RESULT="$(osascript <<EOF
set theChoice to choose folder with prompt "$(esc "$PROMPT")" $MULTI_CLAUSE
if class of theChoice is list then
  set out to ""
  repeat with f in theChoice
    set out to out & POSIX path of f & linefeed
  end repeat
  return out
else
  return POSIX path of theChoice
end if
EOF
)" || die "user cancelled or chooser failed"
else
  RESULT="$(osascript <<EOF
set theChoice to choose file with prompt "$(esc "$PROMPT")" $MULTI_CLAUSE
if class of theChoice is list then
  set out to ""
  repeat with f in theChoice
    set out to out & POSIX path of f & linefeed
  end repeat
  return out
else
  return POSIX path of theChoice
end if
EOF
)" || die "user cancelled or chooser failed"
fi

printf '%s\n' "$RESULT" | sed '/^$/d'
