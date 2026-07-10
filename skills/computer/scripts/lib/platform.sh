#!/usr/bin/env bash
# OS detection and portable primitives (Bash 3.2+).
# shellcheck disable=SC2034

# Escape for double-quoted AppleScript strings (defined here so platform is self-contained)
as_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

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
  if [[ -n "${XDG_DOWNLOAD_DIR:-}" && -d "${XDG_DOWNLOAD_DIR}" ]]; then
    printf '%s\n' "$XDG_DOWNLOAD_DIR"
    return
  fi
  if [[ -d "${HOME}/Downloads" ]]; then
    printf '%s\n' "${HOME}/Downloads"
    return
  fi
  if [[ -f "${HOME}/.config/user-dirs.dirs" ]]; then
    local d
    d="$(grep -E '^XDG_DOWNLOAD_DIR=' "${HOME}/.config/user-dirs.dirs" 2>/dev/null | cut -d= -f2- | tr -d '"' | sed "s|\$HOME|${HOME}|")"
    if [[ -n "$d" && -d "$d" ]]; then
      printf '%s\n' "$d"
      return
    fi
  fi
  printf '%s\n' "${HOME}/Downloads"
}

tcu_open() {
  local target="$1"
  case "$TCU_OS" in
    macos) open "$target" ;;
    linux)
      command -v xdg-open >/dev/null 2>&1 || return 1
      xdg-open "$target" >/dev/null 2>&1 &
      ;;
    windows) cmd.exe /c start "" "$target" 2>/dev/null || return 1 ;;
    *) return 1 ;;
  esac
}

tcu_open_with_app() {
  local app="$1" target="${2:-}"
  case "$TCU_OS" in
    macos)
      if [[ -n "$target" ]]; then open -a "$app" "$target"
      else open -a "$app"
      fi
      ;;
    linux)
      if [[ -n "$target" ]]; then "$app" "$target" >/dev/null 2>&1 &
      else "$app" >/dev/null 2>&1 &
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_reveal() {
  local target="$1"
  case "$TCU_OS" in
    macos) open -R "$target" ;;
    linux)
      local dir
      if [[ -d "$target" ]]; then dir="$target"; else dir="$(dirname "$target")"; fi
      command -v xdg-open >/dev/null 2>&1 || return 1
      xdg-open "$dir" >/dev/null 2>&1 &
      ;;
    *) return 1 ;;
  esac
}

tcu_clipboard_get() {
  case "$TCU_OS" in
    macos) pbpaste ;;
    linux)
      if command -v wl-paste >/dev/null 2>&1; then wl-paste
      elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
      elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --output
      else return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_clipboard_set() {
  case "$TCU_OS" in
    macos) pbcopy ;;
    linux)
      if command -v wl-copy >/dev/null 2>&1; then wl-copy
      elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
      elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input
      else return 1
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
        local et em es as
        et="$(as_escape "$title")"
        em="$(as_escape "$message")"
        as="display notification \"${em}\" with title \"${et}\""
        if [[ -n "$subtitle" ]]; then
          es="$(as_escape "$subtitle")"
          as+=" subtitle \"${es}\""
        fi
        if [[ -n "$sound" ]]; then
          as+=" sound name \"$(as_escape "$sound")\""
        fi
        osascript -e "$as"
      elif command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "$title" -message "$message"
      else
        return 1
      fi
      ;;
    linux)
      command -v notify-send >/dev/null 2>&1 || return 1
      notify-send "$title" "$message"
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

# Graceful app quit (macOS AppleScript; Linux best-effort)
tcu_quit_app() {
  local app="$1"
  case "$TCU_OS" in
    macos)
      command -v osascript >/dev/null 2>&1 || return 1
      osascript -e "tell application \"$(as_escape "$app")\" to quit" 2>/dev/null
      ;;
    linux)
      # exact process name match only
      if pgrep -x "$app" >/dev/null 2>&1; then
        pkill -x "$app" 2>/dev/null || return 1
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

# Force quit: exact name match only (never substring)
tcu_force_quit_app() {
  local app="$1"
  if pgrep -x "$app" >/dev/null 2>&1; then
    pkill -x "$app" 2>/dev/null || killall "$app" 2>/dev/null || return 1
    return 0
  fi
  # macOS apps often use different process names; try osascript first then fail
  if [[ "$TCU_OS" == "macos" ]] && command -v osascript >/dev/null 2>&1; then
    osascript -e "tell application \"$(as_escape "$app")\" to quit" 2>/dev/null || true
    sleep 0.3
    if pgrep -x "$app" >/dev/null 2>&1; then
      pkill -x "$app" 2>/dev/null || return 1
    fi
    return 0
  fi
  return 1
}

tcu_activate_app() {
  local app="$1"
  case "$TCU_OS" in
    macos)
      command -v osascript >/dev/null 2>&1 || return 1
      osascript -e "tell application \"$(as_escape "$app")\" to activate"
      ;;
    linux)
      if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -a "$app" 2>/dev/null || "$app" >/dev/null 2>&1 &
      else
        "$app" >/dev/null 2>&1 &
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_list_apps() {
  case "$TCU_OS" in
    macos)
      command -v osascript >/dev/null 2>&1 || return 1
      # One app per line (avoid comma-split)
      osascript <<'APPLESCRIPT'
tell application "System Events"
  set names to name of every process whose background only is false
end tell
set out to ""
repeat with n in names
  set out to out & n & linefeed
end repeat
return out
APPLESCRIPT
      ;;
    linux)
      if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -l | awk '{$1=$2=$3=""; sub(/^ +/,""); print}' | sort -u
      else
        ps -eo comm= | sort -u
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_frontmost_app() {
  case "$TCU_OS" in
    macos)
      command -v osascript >/dev/null 2>&1 || return 1
      osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'
      ;;
    linux)
      if command -v xdotool >/dev/null 2>&1; then
        xdotool getactivewindow getwindowname 2>/dev/null
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

tcu_trash() {
  local p="$1"
  case "$TCU_OS" in
    macos)
      if command -v trash >/dev/null 2>&1; then
        trash "$p"
      else
        local abs
        abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
        osascript -e "tell application \"Finder\" to delete POSIX file \"$(as_escape "$abs")\"" >/dev/null
      fi
      ;;
    linux)
      if command -v gio >/dev/null 2>&1; then
        gio trash "$p"
      elif command -v trash-put >/dev/null 2>&1; then
        trash-put "$p"
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}
