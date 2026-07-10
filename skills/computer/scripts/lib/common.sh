#!/usr/bin/env bash
# Shared helpers for Terminal Computer Use scripts.
# shellcheck disable=SC2034
# Compatible with Bash 3.2+ (macOS /bin/bash).

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

require_macos() {
  [[ "$TCU_OS" == "macos" ]] || die "this command requires macOS (detected: $TCU_OS)"
}

# Expand leading ~ only (literal path; no word-split, no glob)
expand_user() {
  local p="${1:-}"
  [[ -n "$p" ]] || die "expand_user: empty path"
  if [[ "$p" == "~" ]]; then
    printf '%s\n' "$HOME"
  elif [[ "$p" == "~/"* ]]; then
    printf '%s\n' "${HOME}/${p#~/}"
  else
    printf '%s\n' "$p"
  fi
}

abspath() {
  local p
  p="$(expand_user "${1:-}")"
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
  mkdir -p "$(dirname "$1")"
}

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

safe_mode() {
  is_truthy "${TCU_SAFE_MODE:-0}"
}

# Apply TCU_SAFE_MODE: force dry-run unless already dry
# Usage: DRY=$(apply_safe_mode "$DRY")  where DRY is true|false
apply_safe_mode() {
  local dry="$1"
  if safe_mode && [[ "$dry" != "true" ]]; then
    log "TCU_SAFE_MODE=1 → forcing dry-run"
    echo "true"
  else
    echo "$dry"
  fi
}

# Refuse catastrophic mutation targets (files or dirs)
assert_safe_path() {
  local p="$1"
  local resolved home home_p
  p="$(expand_user "$p")"
  home="$HOME"
  # macOS may physicalize /Users → /System/Volumes/Data/Users
  home_p="$(cd "$home" 2>/dev/null && pwd -P 2>/dev/null || echo "$home")"

  if [[ -e "$p" ]]; then
    if [[ -d "$p" ]]; then
      resolved="$(cd "$p" && pwd 2>/dev/null)"
      resolved_p="$(cd "$p" && pwd -P 2>/dev/null || echo "$resolved")"
    else
      local parent_log parent_p
      parent_log="$(cd "$(dirname "$p")" && pwd)"
      parent_p="$(cd "$(dirname "$p")" && pwd -P 2>/dev/null || echo "$parent_log")"
      resolved="${parent_log}/$(basename "$p")"
      resolved_p="${parent_p}/$(basename "$p")"
    fi
  else
    local parent
    parent="$(cd "$(dirname "$p")" 2>/dev/null && pwd)" || die "refusing path with missing parent: $p"
    resolved="${parent}/$(basename "$p")"
    resolved_p="$resolved"
  fi

  # Exact home / root only (not "anything under home")
  if [[ "$resolved" == "/" || "$resolved_p" == "/" \
     || "$resolved" == "$home" || "$resolved" == "$home/" \
     || "$resolved_p" == "$home_p" || "$resolved_p" == "$home_p/" ]]; then
    die "refusing unsafe path: $p"
  fi
  case "$resolved" in
    /System|/usr|/bin|/sbin|/etc) die "refusing unsafe path: $p" ;;
  esac
  case "$resolved_p" in
    /System|/usr|/bin|/sbin|/etc) die "refusing unsafe path: $p" ;;
  esac
}

