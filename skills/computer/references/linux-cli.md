# Linux CLI reference (Terminal Computer Use)

## Open / reveal

```bash
xdg-open ~/Documents
xdg-open https://example.com
```

## Clipboard

```bash
# Wayland
wl-copy <<< "hello"
wl-paste

# X11
echo hello | xclip -selection clipboard
xclip -selection clipboard -o
```

## Notifications

```bash
notify-send "Title" "Message"
```

## Screenshots

```bash
gnome-screenshot -f /tmp/cap.png
scrot /tmp/cap.png
import -window root /tmp/cap.png   # ImageMagick
```

## Trash

```bash
gio trash ./file
trash-put ./file   # trash-cli
```

## Apps (best-effort)

```bash
pgrep -a firefox
wmctrl -l          # if installed
```

Prefer skill scripts (`open-target.sh`, `clipboard.sh`, `notify.sh`) which pick backends automatically.
