#!/usr/bin/env bash
# Terminal Computer Use — multi-agent installer (Bash 3.2+)
# usage: ./install.sh [--dry-run] [--project] [--symlink] [--force] [--agent NAME]...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="${ROOT}/skills/computer"
CMD_SRC="${ROOT}/agents/computer.md"
MARKER=".tcu-managed"

DRY=false
SYMLINK=false
PROJECT=false
FORCE=false
AGENTS=() # empty = auto-detect existing agent homes

usage() {
  cat <<'EOF'
usage: install.sh [options]

Install the `computer` skill into coding-agent skill directories.

Options:
  --dry-run       Print actions only
  --project       Install into current project only
  --symlink       Symlink instead of copy (dev-friendly)
  --force         Overwrite unmanaged destinations
  --agent NAME    grok|claude|cursor|codex|agents|all (repeatable)
  -h, --help      Show help

By default only installs into agent dirs that already exist
(~/.claude, ~/.grok, …), plus always ensures ~/.agents/skills.

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --agent grok --symlink
  ./install.sh --project --force
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
    --force) FORCE=true; shift ;;
    --agent)
      [[ $# -ge 2 ]] || { log "error: --agent requires a name"; exit 1; }
      AGENTS+=("$2"); shift 2
      ;;
    *) log "error: unknown arg: $1"; usage 1 ;;
  esac
done

[[ -f "${SKILL_SRC}/SKILL.md" ]] || { log "error: missing ${SKILL_SRC}/SKILL.md"; exit 1; }

# Table: name|global_skill_path|optional_command_path|detect_dir
# detect_dir empty = always candidate when selected
AGENT_ROWS="
grok|${HOME}/.grok/skills/computer|${HOME}/.grok/commands/computer.md|${HOME}/.grok
claude|${HOME}/.claude/skills/computer||${HOME}/.claude
cursor|${HOME}/.cursor/skills/computer||${HOME}/.cursor
agents|${HOME}/.agents/skills/computer||${HOME}/.agents
codex|${HOME}/.agents/skills/computer||${HOME}/.agents
"

should_agent() {
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

targets=()       # skill install paths
cmd_targets=()   # optional slash command files

add_unique() {
  local arr_name="$1" val="$2"
  local i
  eval "local n=\${#$arr_name[@]}"
  i=0
  while [[ $i -lt $n ]]; do
    eval "local cur=\${$arr_name[$i]}"
    [[ "$cur" == "$val" ]] && return
    i=$((i + 1))
  done
  eval "$arr_name+=(\"\$val\")"
}

if $PROJECT; then
  add_unique targets "$(pwd)/.agents/skills/computer"
  # only other project paths if parent already used in this project
  [[ -d "$(pwd)/.claude" ]] && add_unique targets "$(pwd)/.claude/skills/computer"
  [[ -d "$(pwd)/.grok" ]] && add_unique targets "$(pwd)/.grok/skills/computer"
  [[ -d "$(pwd)/.cursor" ]] && add_unique targets "$(pwd)/.cursor/skills/computer"
else
  # always include generic agents path when no filter or agents/codex/all
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    name="${row%%|*}"
    rest="${row#*|}"
    skill="${rest%%|*}"
    rest2="${rest#*|}"
    cmd="${rest2%%|*}"
    detect="${rest2#*|}"

    should_agent "$name" || continue

    # auto mode: only if detect dir exists, except always allow agents
    if [[ ${#AGENTS[@]} -eq 0 ]]; then
      if [[ "$name" == "agents" || "$name" == "codex" ]]; then
        add_unique targets "$skill"
      elif [[ -d "$detect" ]]; then
        add_unique targets "$skill"
      fi
    else
      add_unique targets "$skill"
    fi

    if [[ -n "$cmd" && -f "$CMD_SRC" ]]; then
      if should_agent grok || should_agent all || [[ ${#AGENTS[@]} -eq 0 && -d "${HOME}/.grok" ]]; then
        if [[ "$name" == "grok" ]]; then
          add_unique cmd_targets "$cmd"
        fi
      fi
    fi
  done <<EOF
$(printf '%s\n' "$AGENT_ROWS")
EOF
fi

# Ensure at least agents path if nothing matched
if [[ ${#targets[@]} -eq 0 ]]; then
  add_unique targets "${HOME}/.agents/skills/computer"
fi

is_managed() {
  local dest="$1"
  [[ -L "$dest" ]] && return 0
  [[ -f "${dest}/${MARKER}" ]] && return 0
  [[ ! -e "$dest" ]] && return 0
  return 1
}

install_one() {
  local dest="$1"
  if [[ -e "$dest" ]] && ! is_managed "$dest" && ! $FORCE; then
    log "skip (unmanaged, use --force): $dest"
    return 0
  fi

  if $DRY; then
    if $SYMLINK; then
      log "[dry-run] ln -sfn $SKILL_SRC $dest"
    else
      log "[dry-run] install → $dest"
    fi
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if $SYMLINK; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      if is_managed "$dest" || $FORCE; then
        rm -rf "$dest"
      else
        log "skip (unmanaged): $dest"
        return 0
      fi
    fi
    ln -sfn "$SKILL_SRC" "$dest"
    log "symlinked: $dest → $SKILL_SRC"
    return 0
  fi

  # copy install
  if [[ -L "$dest" ]]; then
    rm -f "$dest"
  fi
  mkdir -p "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.DS_Store' "${SKILL_SRC}/" "${dest}/"
  else
    # careful replace of managed tree only
    find "$dest" -mindepth 1 -maxdepth 1 ! -name "$MARKER" -exec rm -rf {} + 2>/dev/null || true
    cp -R "${SKILL_SRC}/." "${dest}/"
  fi
  printf 'terminal-computer-use\n' > "${dest}/${MARKER}"
  find "$dest/scripts" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} \; 2>/dev/null || true
  log "installed: $dest"
}

log "Terminal Computer Use installer"
log "source: $SKILL_SRC"
log "mode:   $(if $DRY; then echo dry-run; else echo execute; fi) $(if $SYMLINK; then echo symlink; else echo copy; fi)$(if $FORCE; then echo " force"; fi)"
log "targets (${#targets[@]}):"
local_t=
for local_t in "${targets[@]}"; do log "  - $local_t"; done
log

for local_t in "${targets[@]}"; do
  install_one "$local_t"
done

if [[ ${#cmd_targets[@]} -gt 0 ]]; then
  for c in "${cmd_targets[@]}"; do
    if $DRY; then
      log "[dry-run] slash command → $c"
    else
      mkdir -p "$(dirname "$c")"
      cp "$CMD_SRC" "$c"
      log "slash command: $c"
    fi
  done
fi

if ! $DRY && [[ ${#targets[@]} -gt 0 ]]; then
  log
  log "Done. Verify:  bash \"${targets[0]}/scripts/doctor.sh\""
  log "Try:     /computer organize my desktop"
fi
