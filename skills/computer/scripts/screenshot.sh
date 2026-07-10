#!/usr/bin/env bash
# purpose: capture screen / window / selection to a file
# usage: screenshot.sh [--interactive|--window|--full] [--path PATH]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: screenshot.sh [--full|--window|--interactive] [--path PATH]

  --full         entire screen (default, non-interactive)
  --window       capture a window (interactive where supported)
  --interactive  selection rectangle
  --path PATH    output file (default: Desktop/screenshot-TIMESTAMP.png)

Prints the output path on stdout.
EOF
  exit "${1:-0}"
}

MODE="full"
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --full) MODE="full"; shift ;;
    --window) MODE="window"; shift ;;
    --interactive|--select) MODE="interactive"; shift ;;
    --path) OUT="$2"; shift 2 ;;
    *) die "unknown arg: $1" ;;
  esac
done

if [[ -z "$OUT" ]]; then
  OUT="$(tcu_desktop_dir)/screenshot-$(date +%Y%m%d-%H%M%S).png"
fi
[[ "$OUT" == ~* ]] && OUT="${OUT/#\~/$HOME}"
ensure_parent "$OUT"

tcu_screenshot "$OUT" "$MODE" || die "screenshot failed (permission denied or tool missing?)"
[[ -f "$OUT" ]] || die "screenshot failed (cancelled or permission denied?)"
log "screenshot saved: $OUT"
printf '%s\n' "$OUT"
