#!/usr/bin/env bash
# purpose: report availability of computer-use related tools
# usage: which-tools.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: which-tools.sh

Print which runtime/tools are available for Terminal Computer Use.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

check() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf 'OK   %-16s %s\n' "$name" "$(command -v "$name")"
  else
    printf 'MISS %-16s\n' "$name"
  fi
}

echo "=== Terminal Computer Use tool check ==="
echo "OS: $TCU_OS"
echo "SKILL_ROOT: $SKILL_ROOT"
echo
for c in bash python3 ruby osascript open pbcopy pbpaste screencapture \
         xdg-open notify-send wl-copy wl-paste xclip gio jq; do
  check "$c"
done

echo
echo "=== skill library ==="
find "$SCRIPTS_DIR" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.rb' \) \
  2>/dev/null | sort | while read -r f; do
  printf '  %s\n' "$(basename "$f")"
done
