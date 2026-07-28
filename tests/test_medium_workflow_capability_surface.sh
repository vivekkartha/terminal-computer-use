#!/usr/bin/env bash
# Structural capability surface test for analysis claims:
# TCU v0.3.x supports open URL + clipboard, not browser click/fill/publish.
# Drives real installed/repo scripts and README — fails if contract drifts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="${ROOT}/skills/computer/scripts"
SKILL_MD="${ROOT}/skills/computer/SKILL.md"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

[[ -d "$SCRIPTS" ]] || fail "scripts dir missing: $SCRIPTS"
[[ -f "$SKILL_MD" ]] || fail "SKILL.md missing"
[[ -f "$README" ]] || fail "README missing"

# --- real entry points ---
open_help="$(bash "${SCRIPTS}/open-target.sh" --help 2>&1)" || true
echo "$open_help" | grep -qi 'url' || fail "open-target.sh --help must mention URL"
echo "$open_help" | grep -q 'https://example.com' || fail "open-target.sh --help must show https example"
pass "open-target.sh opens URLs (help contract)"

clip_help="$(bash "${SCRIPTS}/clipboard.sh" --help 2>&1)" || true
echo "$clip_help" | grep -qE 'get|set' || fail "clipboard.sh --help must document get/set"
pass "clipboard.sh get/set present"

# --- absences: no first-class browser automation ---
[[ ! -f "${SCRIPTS}/browser.sh" ]] || fail "browser.sh must not exist in v0.3 analysis baseline (or update this test for 0.4+)"
for name in playwright puppeteer selenium medium-publish; do
  if find "$SCRIPTS" -maxdepth 2 -iname "*${name}*" | grep -q .; then
    fail "unexpected browser/publish artifact matching *${name}* under scripts/"
  fi
done
pass "no browser.sh / playwright / medium-publish scripts"

# --- docs contract ---
grep -q 'arbitrary GUI clicking' "$README" || fail "README must exclude arbitrary GUI clicking"
grep -q 'filling web forms' "$README" || fail "README must exclude filling web forms"
grep -q 'not GUI pixel control' "$SKILL_MD" || fail "SKILL.md must state not GUI pixel control"
grep -q 'open-target.sh' "$SKILL_MD" || fail "SKILL.md capability map must list open-target.sh"
grep -q 'clipboard.sh' "$SKILL_MD" || fail "SKILL.md capability map must list clipboard.sh"
pass "README/SKILL docs exclude GUI click/form-fill; list open+clipboard"

# --- script inventory includes expected helpers, not browser ---
# Bash 3.2-safe (macOS /bin/bash): no mapfile
inv_file="$(mktemp)"
find "$SCRIPTS" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -exec basename {} \; | sort >"$inv_file"
grep -qx 'open-target.sh' "$inv_file" || fail "open-target.sh missing from inventory"
grep -qx 'clipboard.sh' "$inv_file" || fail "clipboard.sh missing"
grep -qx 'screenshot.sh' "$inv_file" || fail "screenshot.sh missing"
grep -qx 'osascript-run.sh' "$inv_file" || fail "osascript-run.sh missing"
count="$(wc -l <"$inv_file" | tr -d ' ')"
rm -f "$inv_file"
pass "inventory has open-target, clipboard, screenshot, osascript-run (${count} scripts)"

echo
echo "SUMMARY: TCU capability surface matches Medium analysis baseline"
echo "  can: open URL (open-target), system clipboard"
echo "  cannot (supported): browser DOM click/fill/publish"
echo "ALL PASSED"
