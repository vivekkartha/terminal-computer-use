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

Report version, OS, skill paths, tools, and first-run hints.
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

# Version from repo root or installed skill parent
read_version() {
  local candidates=(
    "${SKILL_ROOT}/../../VERSION"
    "${SKILL_ROOT}/../VERSION"
    "${SKILL_ROOT}/VERSION"
  )
  # When installed via symlink, repo root is two levels up from skills/computer
  local real_scripts real_skill repo
  real_scripts="$(cd "$SCRIPTS_DIR" && pwd -P 2>/dev/null || pwd)"
  real_skill="$(cd "$real_scripts/.." && pwd)"
  candidates+=("${real_skill}/../../VERSION" "${real_skill}/../VERSION")
  # package.json sibling
  local c v
  for c in "${candidates[@]}"; do
    if [[ -f "$c" ]]; then
      tr -d '[:space:]' <"$c"
      return
    fi
  done
  # parse package.json near skill
  for c in "${real_skill}/../../package.json" "${real_skill}/../package.json"; do
    if [[ -f "$c" ]] && have python3; then
      python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$c" 2>/dev/null && return
    fi
  done
  echo "unknown"
}

VER="$(read_version)"

echo "=== Terminal Computer Use doctor ==="
echo "version:     $VER"
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
    have osascript && pass "osascript" || warn_ "osascript missing (app control limited)"
    have pbcopy && pass "pbcopy/pbpaste" || warn_ "pbcopy"
    have screencapture && pass "screencapture" || warn_ "screencapture"
    if have osascript; then
      if osascript -e 'tell application "System Events" to get name of first process' >/dev/null 2>&1; then
        pass "System Events (Automation)"
      else
        warn_ "System Events blocked — enable Automation for your terminal"
        warn_ "  System Settings → Privacy & Security → Automation"
        warn_ "  System Settings → Privacy & Security → Accessibility"
      fi
    fi
    ;;
  linux)
    have xdg-open && pass "xdg-open" || warn_ "xdg-open (install xdg-utils)"
    have notify-send && pass "notify-send" || warn_ "notify-send (install libnotify)"
    if have wl-copy || have xclip || have xsel; then
      pass "clipboard (wl-copy/xclip/xsel)"
    else
      warn_ "clipboard missing — install wl-clipboard or xclip"
    fi
    if have gio || have trash-put; then
      pass "trash (gio/trash-cli)"
    else
      warn_ "trash helper missing — install trash-cli or use gio"
    fi
    ;;
  *)
    warn_ "unsupported OS for full automation: $TCU_OS"
    warn_ "Windows is not supported yet"
    ;;
esac

echo
echo "=== scripts ==="
count=0
# Bash 3.2: avoid process substitution with -d '' if needed
count="$(find "$SCRIPTS_DIR" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$count" -gt 0 ]]; then
  pass "$count top-level scripts"
else
  fail_ "no scripts in $SCRIPTS_DIR"
fi

if [[ -f "$SKILL_ROOT/SKILL.md" ]]; then
  pass "SKILL.md present"
else
  fail_ "SKILL.md missing at $SKILL_ROOT"
fi

echo
echo "=== try next ==="
echo "  python3 \"${SCRIPTS_DIR}/fs-organize.py\" --dry-run \"\$(bash \"${SCRIPTS_DIR}/desktop-path.sh\")\""
echo "  bash \"${SCRIPTS_DIR}/notify.sh\" --title TCU \"doctor ok\""
echo "  /computer organize my desktop"
echo
if [[ "$warn" -gt 0 ]]; then
  echo "Docs: https://github.com/vivekkartha/terminal-computer-use/blob/main/docs/TROUBLESHOOTING.md"
fi
echo "=== summary: ok=$ok warn=$warn fail=$fail ==="
[[ "$fail" -eq 0 ]]
