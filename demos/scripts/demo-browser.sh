#!/usr/bin/env bash
# Demo: headed browser open + click/fill on a data URL (no network publish).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
S="${ROOT}/skills/computer/scripts"
export TCU_STATE_DIR="${TMPDIR:-/tmp}/tcu-demo-browser-$$"
mkdir -p "$TCU_STATE_DIR"

cleanup() {
  bash "$S/browser.sh" stop >/dev/null 2>&1 || true
  rm -rf "$TCU_STATE_DIR"
}
trap cleanup EXIT

echo "==> start headless browser"
bash "$S/browser.sh" start --headless

HTML='data:text/html,<html><body><input id="t"/><button id="b">Go</button><div id="out"></div><script>document.getElementById("b").onclick=()=>{document.getElementById("out").textContent=document.getElementById("t").value;}</script></body></html>'

echo "==> open demo page"
bash "$S/browser.sh" open "$HTML"
echo "==> fill + click"
bash "$S/browser.sh" fill '#t' 'tcu-demo'
bash "$S/browser.sh" click '#b'
out="$(bash "$S/browser.sh" text '#out')"
echo "out=$out"
[[ "$out" == *tcu-demo* ]] || { echo "FAIL unexpected: $out"; exit 1; }
echo "demo-browser: OK"
