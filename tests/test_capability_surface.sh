#!/usr/bin/env bash
# Structural capability surface: open URL + clipboard; browser automation absent.
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

# --- browser automation must be gone (0.5+) ---
[[ ! -f "${SCRIPTS}/browser.sh" ]] || fail "browser.sh must not exist"
[[ ! -f "${SCRIPTS}/chrome-cdp.sh" ]] || fail "chrome-cdp.sh must not exist"
[[ ! -f "${SCRIPTS}/lib/browser.py" ]] || fail "lib/browser.py must not exist"
[[ ! -f "${SCRIPTS}/lib/browser_daemon.py" ]] || fail "lib/browser_daemon.py must not exist"
[[ ! -f "${SCRIPTS}/lib/browser_policy.py" ]] || fail "lib/browser_policy.py must not exist"
[[ ! -f "${ROOT}/skills/computer/references/browser.md" ]] || fail "references/browser.md must not exist"
pass "browser automation scripts/docs removed"

# --- docs refuse contract ---
grep -qi 'not supported' "$SKILL_MD" || fail "SKILL.md must say browser automation not supported"
grep -qi 'browser automation' "$SKILL_MD" || fail "SKILL.md must mention browser automation"
grep -qiE 'not supported|No browser' "$README" || fail "README must state browser automation not supported"
grep -q 'not GUI pixel control' "$SKILL_MD" || fail "SKILL.md must state not GUI pixel control"
# must not advertise removed entry points as runnable capabilities
if grep -qE '`browser\.sh`|browser\.sh ·|medium-draft|medium-publish' "$README"; then
  fail "README must not advertise browser.sh / medium-* as capabilities"
fi
if grep -qE '`browser\.sh`|medium-draft|medium-publish' "$SKILL_MD"; then
  fail "SKILL.md must not list browser.sh / medium-* as capabilities"
fi
pass "docs refuse browser automation; no capability ads for removed tools"

# inventory
inv_file="$(mktemp)"
find "$SCRIPTS" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -exec basename {} \; | sort >"$inv_file"
grep -qx 'open-target.sh' "$inv_file" || fail "open-target.sh missing from inventory"
grep -qx 'clipboard.sh' "$inv_file" || fail "clipboard.sh missing"
if grep -qx 'browser.sh' "$inv_file"; then
  fail "browser.sh still in inventory"
fi
count="$(wc -l <"$inv_file" | tr -d ' ')"
rm -f "$inv_file"
pass "inventory has open-target + clipboard, no browser (${count} scripts)"

echo
echo "SUMMARY: TCU capability surface — desktop only"
echo "  can: open URL (no control), clipboard, files, apps, notify"
echo "  cannot: browser DOM / Playwright / captcha / automated publish"
echo "ALL PASSED"
