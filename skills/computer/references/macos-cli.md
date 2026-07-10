# macOS CLI reference (Terminal Computer Use)

Quick recipes when a library script is not enough.

## Files & folders

```bash
open ~/Documents
open -R ./file.txt
mdfind "kMDItemDisplayName == 'report.pdf'c"
ditto src/ dest/
rsync -a --dry-run src/ dest/
```

## Apps

```bash
open -a "Google Chrome"
open -a "Visual Studio Code" .
osascript -e 'tell application "Safari" to quit'
```

## Clipboard

```bash
pbpaste
echo hello | pbcopy
```

## Notifications

```bash
osascript -e 'display notification "Done" with title "TCU"'
```

## Screenshots

```bash
screencapture -x ~/Desktop/cap.png
screencapture -i ~/Desktop/sel.png
screencapture -w ~/Desktop/win.png
```

Prefer skill scripts under `scripts/` first; extend that library instead of scattering one-offs.
