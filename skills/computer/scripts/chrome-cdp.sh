#!/usr/bin/env bash
# purpose: launch real Google Chrome with CDP for captcha-heavy sites (Medium)
# usage: chrome-cdp.sh [--port 9222] [--url URL]
# then: browser.sh connect --port 9222
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PORT=9222
URL="https://medium.com/m/signin"
PROFILE="${TCU_CHROME_PROFILE:-$HOME/.tcu/chrome-medium}"

usage() {
  cat <<EOF
usage: chrome-cdp.sh [--port N] [--url URL] [--profile DIR]

Launch real Google Chrome (not Playwright Chromium) with remote debugging.
Pass Cloudflare/captcha + Medium login once in this window; session persists
in PROFILE (default: ~/.tcu/chrome-medium).

Then attach TCU:
  bash "\$SCRIPTS/browser.sh" connect --port ${PORT}
  bash "\$SCRIPTS/browser.sh" open https://medium.com/new-story
EOF
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --port) PORT="$2"; shift 2 ;;
    --url) URL="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    *) die "unknown: $1" ;;
  esac
done

CHROME=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "$(command -v google-chrome 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)"
do
  [[ -n "$c" && -x "$c" ]] && { CHROME="$c"; break; }
done
[[ -n "$CHROME" ]] || die "Google Chrome not found. Install Chrome or set path."

mkdir -p "$PROFILE"
# if already listening, just report
if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
  log "CDP already up on port $PORT — connect with: browser.sh connect --port $PORT"
  exit 0
fi

log "starting Chrome CDP port=$PORT profile=$PROFILE"
# detached real Chrome
nohup "$CHROME" \
  --remote-debugging-port="$PORT" \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir="$PROFILE" \
  --no-first-run \
  --no-default-browser-check \
  "$URL" \
  >/dev/null 2>&1 &

# wait for port
for i in $(seq 1 50); do
  if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
    log "Chrome CDP ready: http://127.0.0.1:$PORT"
    log "1) Complete captcha + Medium login in that window"
    log "2) bash \"$SCRIPT_DIR/browser.sh\" connect --port $PORT"
    exit 0
  fi
  sleep 0.2
done
die "Chrome started but CDP port $PORT never opened"
