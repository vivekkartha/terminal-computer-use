#!/usr/bin/env bash
# Shared filesystem ops for move/copy (Bash 3.2+).
# shellcheck disable=SC2034
# Source after common.sh

# Parse trailing args: [--dry-run] <src>... <dest>
# Sets: FS_DRY (true|false), FS_SRCS (array), FS_DEST (string)
fs_parse_move_args() {
  FS_DRY=false
  FS_SRCS=()
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) return 2 ;;
      --dry-run) FS_DRY=true; shift ;;
      *) args+=("$1"); shift ;;
    esac
  done
  [[ ${#args[@]} -ge 2 ]] || return 1

  # Bash 3.2: no negative indices
  local n last i
  n=${#args[@]}
  last=$((n - 1))
  FS_DEST="$(expand_user "${args[$last]}")"
  FS_SRCS=()
  i=0
  while [[ $i -lt $last ]]; do
    FS_SRCS+=("$(expand_user "${args[$i]}")")
    i=$((i + 1))
  done

  FS_DRY="$(apply_safe_mode "$FS_DRY")"
  return 0
}

# Validate sources exist (literal paths only — agent/shell expands globs)
fs_require_sources() {
  local s
  for s in "$@"; do
    [[ -e "$s" ]] || die "source not found: $s"
    assert_safe_path "$s"
  done
}

# Resolve dest target path for one source.
# multi=true|false  → if multi, dest must be/become directory
# Prints absolute target path
fs_resolve_target() {
  local src="$1" dest="$2" multi="$3"
  local target

  if [[ "$multi" == "true" ]]; then
    if [[ -e "$dest" && ! -d "$dest" ]]; then
      die "dest must be a directory for multiple sources: $dest"
    fi
    target="${dest%/}/$(basename "$src")"
  else
    if [[ -d "$dest" || "$dest" == */ ]]; then
      target="${dest%/}/$(basename "$src")"
    else
      target="$dest"
    fi
  fi
  printf '%s\n' "$target"
}

fs_ensure_dest_dir() {
  local dest="$1" dry="$2" multi="$3" src_count="$4"
  if [[ "$multi" == "true" ]] || [[ -d "$dest" || "$dest" == */ ]]; then
    if [[ "$dry" == "true" ]]; then
      log "[dry-run] mkdir -p ${dest%/}"
    else
      mkdir -p "${dest%/}"
    fi
  else
    if [[ "$dry" == "true" ]]; then
      log "[dry-run] mkdir -p $(dirname "$dest")"
    else
      ensure_parent "$dest"
    fi
  fi
}

# fs_run_batch op dry src... -- dest
# op is mv or cp
fs_run_batch() {
  local op="$1" dry="$2"
  shift 2
  local srcs=() dest="" 
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
      shift
      dest="${1:-}"
      break
    fi
    srcs+=("$1")
    shift
  done
  [[ -n "$dest" && ${#srcs[@]} -gt 0 ]] || die "fs_run_batch: bad args"

  assert_safe_path "$dest"
  fs_require_sources "${srcs[@]}"

  local multi=false
  [[ ${#srcs[@]} -gt 1 ]] && multi=true

  fs_ensure_dest_dir "$dest" "$dry" "$multi" "${#srcs[@]}"

  local s target
  for s in "${srcs[@]}"; do
    target="$(fs_resolve_target "$s" "$dest" "$multi")"
    if [[ "$multi" != "true" && ! -d "$dest" && "$dest" != */ ]]; then
      : # file rename target; parent already ensured
    fi
    if [[ "$dry" == "true" ]]; then
      log "[dry-run] $op $s → $target"
    else
      if [[ "$op" == "mv" ]]; then
        # ensure parent of target
        mkdir -p "$(dirname "$target")"
        mv "$s" "$target"
        log "moved: $s → $target"
      else
        mkdir -p "$(dirname "$target")"
        cp -R "$s" "$target"
        log "copied: $s → $target"
      fi
    fi
  done
}
