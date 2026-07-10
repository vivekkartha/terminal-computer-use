#!/usr/bin/env bash
# purpose: print Desktop or Downloads directory for current OS
# usage: desktop-path.sh [desktop|downloads]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
usage: desktop-path.sh [desktop|downloads]

Print the absolute path of the user's Desktop or Downloads folder.
EOF
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0
which_path="${1:-desktop}"

case "$which_path" in
  desktop|Desktop) tcu_desktop_dir ;;
  downloads|Downloads) tcu_downloads_dir ;;
  *) die "unknown target: $which_path (use desktop|downloads)" ;;
esac
