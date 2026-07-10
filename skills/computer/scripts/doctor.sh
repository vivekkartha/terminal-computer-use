#!/usr/bin/env bash
# purpose: health check for Terminal Computer Use install + tools
# usage: doctor.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: doctor.sh

Report OS, skill paths, and tool availability for Terminal Computer Use.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

ok=0
warn=0
fail=0

pass() { printf '  OK   %s\n' "$*"; ok=$((ok + 1)); }
warn_() { printf '  WARN %s\n' "$*"; warn=$((warn + 1)); }
fail_() { printf '  FAIL %s\n' "$*"; fail=$((fail + 1)); }

echo "=== Terminal Computer Use doctor ==="
echo "OS:          $TCU_OS ($(uname -s) $(uname -m))"
echo "SKILL_ROOT:  $SKILL_ROOT"
echo "SCRIPTS:     $SCRIPTS_DIR"
echo "Desktop:     $(tcu_desktop_dir)"
echo

echo "=== core ==="
have bash && pass "bash" || fail_ "bash"
have python3 && pass "python3" || fail_ "python3"

echo
echo "=== platform tools ==="
case "$TCU_OS" in
  macos)
    have open && pass "open" || fail_ "open"
    have osascript && pass "osascript" || warn_ "osascript"
    have pbcopy && pass "pbcopy/pbpaste" || warn_ "pbcopy"
    have screencapture && pass "screencapture" || warn_ "screencapture"
    ;;
  linux)
    have xdg-open && pass "xdg-open" || warn_ "xdg-open"
    have notify-send && pass "notify-send" || warn_ "notify-send"
    if have wl-copy || have xclip || have xsel; then
      pass "clipboard (wl-copy/xclip/xsel)"
    else
      warn_ "clipboard helper missing"
    fi
    ;;
  *)
    warn_ "unsupported OS for full automation: $TCU_OS"
    ;;
esac

echo
echo "=== scripts ==="
count=0
while IFS= read -r -d '' f; do
  count=$((count + 1))
done < <(find "$SCRIPTS_DIR" -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) -print0 2>/dev/null)
pass "$count top-level scripts in $SCRIPTS_DIR"

if [[ -f "$SKILL_ROOT/SKILL.md" ]]; then
  pass "SKILL.md present"
else
  fail_ "SKILL.md missing at $SKILL_ROOT"
fi

echo
echo "=== summary: ok=$ok warn=$warn fail=$fail ==="
[[ "$fail" -eq 0 ]]
