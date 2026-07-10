#!/usr/bin/env bash
# purpose: open an app, file, folder, or URL (cross-platform)
# usage: open-target.sh [--app NAME] <path-or-url> [...]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: open-target.sh [--app NAME] <path-or-url> [...]

Open files, folders, URLs, or applications.

Examples:
  open-target.sh ~/Documents
  open-target.sh https://example.com
  open-target.sh --app "Visual Studio Code" ~/project
EOF
  exit "${1:-0}"
}

APP=""
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -a|--app)
      [[ $# -ge 2 ]] || die "--app requires a name"
      APP="$2"
      shift 2
      ;;
    --) shift; TARGETS+=("$@"); break ;;
    -*) die "unknown flag: $1" ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

[[ ${#TARGETS[@]} -gt 0 || -n "$APP" ]] || usage 1

if [[ ${#TARGETS[@]} -eq 0 && -n "$APP" ]]; then
  tcu_open_with_app "$APP" || die "failed to open app: $APP"
  log "opened app: $APP"
  exit 0
fi

for t in "${TARGETS[@]}"; do
  if [[ "$t" == *"://"* ]]; then
    if [[ -n "$APP" ]]; then
      tcu_open_with_app "$APP" "$t" || die "failed to open: $t"
    else
      tcu_open "$t" || die "failed to open: $t"
    fi
    log "opened url: $t"
    continue
  fi
  local_path="$t"
  [[ "$local_path" == ~* ]] && local_path="${local_path/#\~/$HOME}"
  if [[ -n "$APP" ]]; then
    tcu_open_with_app "$APP" "$local_path" || die "failed to open: $local_path"
  else
    tcu_open "$local_path" || die "failed to open: $local_path"
  fi
  log "opened: $local_path${APP:+ (with $APP)}"
done
