#!/usr/bin/env bash
# Shared helpers for Terminal Computer Use scripts.
# shellcheck disable=SC2034

# Resolve skill paths relative to this file (not a hardcoded ~/.grok path).
# Override with TERMINAL_COMPUTER_USE_HOME if needed.
_TCU_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPUTER_SCRIPTS_DIR="$(cd "${_TCU_LIB_DIR}/.." && pwd)"
if [[ -n "${TERMINAL_COMPUTER_USE_HOME:-}" ]]; then
  SKILL_ROOT="$(cd "${TERMINAL_COMPUTER_USE_HOME}" && pwd)"
  COMPUTER_SCRIPTS_DIR="${SKILL_ROOT}/scripts"
else
  SKILL_ROOT="$(cd "${COMPUTER_SCRIPTS_DIR}/.." && pwd)"
fi
COMPUTER_SKILL_DIR="${SKILL_ROOT}"
SCRIPTS_DIR="${COMPUTER_SCRIPTS_DIR}"

# shellcheck source=platform.sh
source "${_TCU_LIB_DIR}/platform.sh"

log()  { printf '%s\n' "$*" >&2; }
die()  { log "error: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  local c
  for c in "$@"; do
    have "$c" || die "required command not found: $c"
  done
}

# Expand ~ and relative paths to absolute
abspath() {
  local p="${1:-}"
  [[ -n "$p" ]] || die "abspath: empty path"
  if [[ "$p" == ~* ]]; then
    p="${p/#\~/$HOME}"
  fi
  if [[ -d "$p" ]]; then
    (cd "$p" && pwd)
  elif [[ -e "$p" ]]; then
    local d b
    d="$(cd "$(dirname "$p")" && pwd)"
    b="$(basename "$p")"
    printf '%s/%s\n' "$d" "$b"
  else
    local d b
    d="$(cd "$(dirname "$p")" 2>/dev/null && pwd)" || die "path not found: $p"
    b="$(basename "$p")"
    printf '%s/%s\n' "$d" "$b"
  fi
}

ensure_parent() {
  local p="$1"
  mkdir -p "$(dirname "$p")"
}

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

# TCU_SAFE_MODE=1 forces dry-run behavior unless caller passes force flag
safe_mode() {
  is_truthy "${TCU_SAFE_MODE:-0}"
}

# Refuse obviously catastrophic targets
assert_safe_path() {
  local p="$1"
  local resolved
  resolved="$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")" 2>/dev/null || resolved="$p"
  case "$resolved" in
    /|"$HOME"|"$HOME/"|"$HOME/." ) die "refusing unsafe path: $p" ;;
  esac
  if [[ "$resolved" == "/" || "$resolved" == "/System" || "$resolved" == "/usr" ]]; then
    die "refusing unsafe path: $p"
  fi
}
