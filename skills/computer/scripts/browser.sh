#!/usr/bin/env bash
# purpose: Playwright DOM browser control (click/fill/type/publish-gated)
# usage: browser.sh <command> [args]
# not vision/pixel CU — selector-based only
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: browser.sh [--i-mean-it] <command> [args]

Session:
  start [--headed|--headless] [--profile PATH] [--channel chrome]
  connect --port 9222          # attach real Chrome (captcha-friendly)
  chrome-cdp.sh                # launch real Chrome + CDP (Medium login)
  stop
  status

Navigate / observe:
  open <url>
  url | title
  text <selector> | html <selector>
  screenshot [out.png] [--full-page]
  wait <selector> [--state visible]
  copy <selector>          # print text (pipe to clipboard.sh set)

Act:
  click <selector>
  fill <selector> <text> | fill <selector> --file PATH
  type <selector> <text> | type <selector> --file PATH
  press <key> [--selector SEL]
  paste <selector> [--file PATH]   # or stdin

Publish (explicit):
  publish-click <selector> --i-mean-it
  medium-draft --title T --body-file PATH
  medium-publish --i-mean-it

Env:
  TCU_SAFE_MODE=1              block mutating actions
  TCU_BROWSER_ALLOWLIST=doms   comma hosts (empty = all)
  TCU_STATE_DIR                default ~/.tcu

Requires: python3, playwright, chromium
  python3 -m pip install playwright && python3 -m playwright install chromium

Examples:
  browser.sh start --headed
  browser.sh open https://example.com
  browser.sh click 'button#go'
  browser.sh medium-draft --title "Hello" --body-file ./draft.md
  browser.sh medium-publish --i-mean-it   # only with user intent
  browser.sh stop
EOF
  exit "${1:-0}"
}

[[ $# -lt 1 ]] && usage 1
case "${1:-}" in
  -h|--help) usage 0 ;;
esac

# Forward all args to Python CLI (handles --i-mean-it anywhere)
exec python3 "${SCRIPT_DIR}/lib/browser.py" "$@"
