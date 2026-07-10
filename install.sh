#!/usr/bin/env bash
# Terminal Computer Use — multi-agent installer
# usage: ./install.sh [--dry-run] [--project] [--symlink] [--agent NAME]...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="${ROOT}/skills/computer"
CMD_SRC="${ROOT}/agents/computer.md"

DRY=false
SYMLINK=false
PROJECT=false
AGENTS=() # empty = auto-detect all known

usage() {
  cat <<'EOF'
usage: install.sh [options]

Install the `computer` skill into coding-agent skill directories.

Options:
  --dry-run       Print actions only
  --project       Install into current project (./.agents/skills/computer)
  --symlink       Symlink instead of copy (dev-friendly)
  --agent NAME    Install only for agent: grok|claude|cursor|codex|agents|all
                  (repeatable; default: all detected + generic agents path)
  -h, --help      Show help

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --agent grok --agent claude
  ./install.sh --project --symlink
EOF
  exit "${1:-0}"
}

log() { printf '%s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --dry-run) DRY=true; shift ;;
    --symlink) SYMLINK=true; shift ;;
    --project) PROJECT=true; shift ;;
    --agent)
      [[ $# -ge 2 ]] || { log "error: --agent requires a name"; exit 1; }
      AGENTS+=("$2"); shift 2
      ;;
    *) log "error: unknown arg: $1"; usage 1 ;;
  esac
done

[[ -f "${SKILL_SRC}/SKILL.md" ]] || { log "error: missing ${SKILL_SRC}/SKILL.md"; exit 1; }

targets=()

add_target() {
  local path="$1"
  targets+=("$path")
}

if $PROJECT; then
  add_target "$(pwd)/.agents/skills/computer"
  add_target "$(pwd)/.claude/skills/computer"
  add_target "$(pwd)/.grok/skills/computer"
  add_target "$(pwd)/.cursor/skills/computer"
else
  # Global installs
  should() {
    local name="$1"
    if [[ ${#AGENTS[@]} -eq 0 ]]; then
      return 0
    fi
    local a
    for a in "${AGENTS[@]}"; do
      [[ "$a" == "all" || "$a" == "$name" ]] && return 0
    done
    return 1
  }

  if should grok; then add_target "${HOME}/.grok/skills/computer"; fi
  if should claude; then add_target "${HOME}/.claude/skills/computer"; fi
  if should cursor; then add_target "${HOME}/.cursor/skills/computer"; fi
  if should agents || should codex; then add_target "${HOME}/.agents/skills/computer"; fi

  # If user passed only specific agents that didn't match, still allow explicit list
  if [[ ${#AGENTS[@]} -gt 0 && ${#targets[@]} -eq 0 ]]; then
    log "error: no targets for agents: ${AGENTS[*]}"
    exit 1
  fi
fi

# Deduplicate (bash 3.2–compatible; no associative arrays)
uniq_targets=()
for t in "${targets[@]}"; do
  dup=false
  for u in "${uniq_targets[@]+"${uniq_targets[@]}"}"; do
    [[ "$u" == "$t" ]] && dup=true && break
  done
  $dup && continue
  uniq_targets+=("$t")
done
targets=("${uniq_targets[@]}")

install_one() {
  local dest="$1"
  if $DRY; then
    if $SYMLINK; then
      log "[dry-run] ln -sfn $SKILL_SRC $dest"
    else
      log "[dry-run] rsync → $dest"
    fi
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if $SYMLINK; then
    rm -rf "$dest"
    ln -sfn "$SKILL_SRC" "$dest"
    log "symlinked: $dest → $SKILL_SRC"
  else
    mkdir -p "$dest"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete --exclude '.DS_Store' "${SKILL_SRC}/" "${dest}/"
    else
      rm -rf "${dest}"
      mkdir -p "$dest"
      cp -R "${SKILL_SRC}/." "${dest}/"
    fi
    # ensure executables
    find "$dest/scripts" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} \; 2>/dev/null || true
    log "installed: $dest"
  fi
}

log "Terminal Computer Use installer"
log "source: $SKILL_SRC"
log "mode:   $(if $DRY; then echo dry-run; else echo execute; fi) $(if $SYMLINK; then echo symlink; else echo copy; fi)"
log "targets (${#targets[@]}):"
for t in "${targets[@]}"; do log "  - $t"; done
log

for t in "${targets[@]}"; do
  install_one "$t"
done

# Grok slash command helper
if ! $PROJECT; then
  install_cmd=false
  if [[ ${#AGENTS[@]} -eq 0 ]] || printf '%s\n' "${AGENTS[@]}" | grep -qxE 'all|grok'; then
    install_cmd=true
  fi
  if $install_cmd && [[ -f "$CMD_SRC" ]]; then
    cmd_dest="${HOME}/.grok/commands/computer.md"
    if $DRY; then
      log "[dry-run] install slash command → $cmd_dest"
    else
      mkdir -p "$(dirname "$cmd_dest")"
      # Point at skill-relative wording; command body is already generic enough
      cp "$CMD_SRC" "$cmd_dest"
      log "slash command: $cmd_dest"
    fi
  fi
fi

# Export hint
if ! $DRY; then
  log
  log "Done. Optional: export TERMINAL_COMPUTER_USE_HOME=\"${targets[0]}\""
  log "Verify:  bash \"${targets[0]}/scripts/doctor.sh\""
  log "Try:     /computer organize my desktop"
fi
