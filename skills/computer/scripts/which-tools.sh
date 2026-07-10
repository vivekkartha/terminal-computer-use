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

Print OS-relevant tools and the skill script library.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

check() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '  OK   %-14s %s\n' "$name" "$(command -v "$name")"
  else
    printf '  MISS %-14s\n' "$name"
  fi
}

echo "Terminal Computer Use — tools ($TCU_OS)"
echo "SKILL_ROOT: $SKILL_ROOT"
echo
echo "core"
check bash
check python3

echo
echo "platform"
case "$TCU_OS" in
  macos)
    for c in open osascript pbcopy pbpaste screencapture; do check "$c"; done
    ;;
  linux)
    for c in xdg-open notify-send wl-copy wl-paste xclip gio; do check "$c"; done
    ;;
  *)
    echo "  (no platform checklist for OS=$TCU_OS)"
    ;;
esac

echo
echo "scripts"
find "$SCRIPTS_DIR" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) \
  2>/dev/null | sort | while read -r f; do
  printf '  %s\n' "$(basename "$f")"
done
