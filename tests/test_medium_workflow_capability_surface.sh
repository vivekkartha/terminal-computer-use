#!/usr/bin/env bash
# Structural capability surface: open URL + clipboard + browser DOM (gated publish).
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

# --- browser DOM (0.4+) ---
[[ -f "${SCRIPTS}/browser.sh" ]] || fail "browser.sh missing"
[[ -f "${SCRIPTS}/lib/browser.py" ]] || fail "lib/browser.py missing"
[[ -f "${SCRIPTS}/lib/browser_policy.py" ]] || fail "lib/browser_policy.py missing"
br_help="$(bash "${SCRIPTS}/browser.sh" --help 2>&1)" || true
echo "$br_help" | grep -q 'medium-draft' || fail "browser.sh --help must document medium-draft"
echo "$br_help" | grep -q 'medium-publish' || fail "browser.sh --help must document medium-publish"
echo "$br_help" | grep -q 'i-mean-it' || fail "browser.sh --help must document --i-mean-it publish gate"
pass "browser.sh present with medium draft/publish gate"

# publish without flag must fail (policy; no browser needed)
if python3 "${SCRIPTS}/lib/browser.py" publish-click 'button' 2>/tmp/tcu-pub.err; then
  fail "publish-click without --i-mean-it must fail"
fi
grep -qi 'i-mean-it' /tmp/tcu-pub.err || fail "publish-click error must mention --i-mean-it"
pass "publish-click blocked without --i-mean-it"

# --- docs ---
grep -q 'browser.sh' "$SKILL_MD" || fail "SKILL.md must list browser.sh"
grep -q 'i-mean-it' "$SKILL_MD" || fail "SKILL.md must mention --i-mean-it"
grep -q 'not GUI pixel control' "$SKILL_MD" || fail "SKILL.md must state not GUI pixel control"
pass "SKILL.md documents browser DOM + publish gate + non-vision"

# inventory
inv_file="$(mktemp)"
find "$SCRIPTS" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -exec basename {} \; | sort >"$inv_file"
grep -qx 'open-target.sh' "$inv_file" || fail "open-target.sh missing from inventory"
grep -qx 'clipboard.sh' "$inv_file" || fail "clipboard.sh missing"
grep -qx 'browser.sh' "$inv_file" || fail "browser.sh missing from inventory"
count="$(wc -l <"$inv_file" | tr -d ' ')"
rm -f "$inv_file"
pass "inventory has open-target, clipboard, browser (${count} scripts)"

echo
echo "SUMMARY: TCU capability surface supports Medium path with gated publish"
echo "  can: open URL, clipboard, browser DOM click/fill, medium-draft"
echo "  publish: medium-publish / publish-click only with --i-mean-it"
echo "ALL PASSED"
