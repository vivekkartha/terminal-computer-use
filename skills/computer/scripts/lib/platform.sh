#!/usr/bin/env bash
# OS detection and portable primitives for Terminal Computer Use.
# shellcheck disable=SC2034

tcu_detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

TCU_OS="${TCU_OS:-$(tcu_detect_os)}"

tcu_desktop_dir() {
  if [[ -n "${XDG_DESKTOP_DIR:-}" && -d "${XDG_DESKTOP_DIR}" ]]; then
    printf '%s\n' "$XDG_DESKTOP_DIR"
    return
  fi
  if [[ -d "${HOME}/Desktop" ]]; then
    printf '%s\n' "${HOME}/Desktop"
    return
  fi
  if [[ -f "${HOME}/.config/user-dirs.dirs" ]]; then
    # shellcheck disable=SC1091
    local d
    d="$(grep -E '^XDG_DESKTOP_DIR=' "${HOME}/.config/user-dirs.dirs" 2>/dev/null | cut -d= -f2- | tr -d '"' | sed "s|\$HOME|${HOME}|")"
    if [[ -n "$d" && -d "$d" ]]; then
      printf '%s\n' "$d"
      return
    fi
  fi
  printf '%s\n' "${HOME}/Desktop"
}

tcu_downloads_dir() {
  if [[ -d "${HOME}/Downloads" ]]; then
    printf '%s\n' "${HOME}/Downloads"
  else
    printf '%s\n' "${HOME}/Downloads"
  fi
}

# Open file, folder, or URL
tcu_open() {
  local target="$1"
  case "$TCU_OS" in
    macos) open "$target" ;;
    linux)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$target" >/dev/null 2>&1 &
      else
        return 1
      fi
      ;;
    windows) cmd.exe /c start "" "$target" 2>/dev/null || return 1 ;;
    *) return 1 ;;
  esac
}

# Open path with a named application (best-effort)
tcu_open_with_app() {
  local app="$1" target="${2:-}"
  case "$TCU_OS" in
    macos)
      if [[ -n "$target" ]]; then
        open -a "$app" "$target"
      else
        open -a "$app"
      fi
      ;;
    linux)
      if [[ -n "$target" ]]; then
        "$app" "$target" >/dev/null 2>&1 &
      else
        "$app" >/dev/null 2>&1 &
      fi
      ;;
    *) return 1 ;;
  esac
}

# Reveal path in file manager
tcu_reveal() {
  local target="$1"
  case "$TCU_OS" in
    macos) open -R "$target" ;;
    linux)
      local dir
      if [[ -d "$target" ]]; then
        dir="$target"
      else
        dir="$(dirname "$target")"
      fi
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$dir" >/dev/null 2>&1 &
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_clipboard_get() {
  case "$TCU_OS" in
    macos) pbpaste ;;
    linux)
      if command -v wl-paste >/dev/null 2>&1; then
        wl-paste
      elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
      elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_clipboard_set() {
  case "$TCU_OS" in
    macos) pbcopy ;;
    linux)
      if command -v wl-copy >/dev/null 2>&1; then
        wl-copy
      elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
      elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_notify() {
  local title="$1" message="$2" subtitle="${3:-}" sound="${4:-}"
  case "$TCU_OS" in
    macos)
      if command -v osascript >/dev/null 2>&1; then
        local esc_title esc_msg esc_sub as
        esc_title="${title//\\/\\\\}"; esc_title="${esc_title//\"/\\\"}"
        esc_msg="${message//\\/\\\\}"; esc_msg="${esc_msg//\"/\\\"}"
        as="display notification \"${esc_msg}\" with title \"${esc_title}\""
        if [[ -n "$subtitle" ]]; then
          esc_sub="${subtitle//\\/\\\\}"; esc_sub="${esc_sub//\"/\\\"}"
          as+=" subtitle \"${esc_sub}\""
        fi
        if [[ -n "$sound" ]]; then
          as+=" sound name \"${sound}\""
        fi
        osascript -e "$as"
      elif command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "$title" -message "$message"
      else
        return 1
      fi
      ;;
    linux)
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$message"
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_screenshot() {
  local out="$1" mode="${2:-full}"
  case "$TCU_OS" in
    macos)
      case "$mode" in
        full) screencapture -x "$out" ;;
        window) screencapture -x -w "$out" ;;
        interactive|select) screencapture -x -i "$out" ;;
        *) return 1 ;;
      esac
      ;;
    linux)
      if command -v gnome-screenshot >/dev/null 2>&1; then
        case "$mode" in
          full) gnome-screenshot -f "$out" ;;
          window) gnome-screenshot -w -f "$out" ;;
          interactive|select) gnome-screenshot -a -f "$out" ;;
          *) return 1 ;;
        esac
      elif command -v import >/dev/null 2>&1; then
        import -window root "$out"
      elif command -v scrot >/dev/null 2>&1; then
        scrot "$out"
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}
