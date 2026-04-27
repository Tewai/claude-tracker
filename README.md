# Claude Tracker

macOS menu bar app for tracking daily & weekly Claude usage limits with auto-reset timers.

## Features

- Live menu bar counter: `Claude 🟢15d 🟡80w`
- Green / yellow / red indicator per limit (80 % = yellow, 100 % = red)
- Countdown to next daily (midnight) and weekly (Monday) reset
- One-click "+1" logging for daily or weekly usage
- Configurable limits via in-app dialogs
- Data persisted in `~/.claude_tracker.json`

## Requirements

- macOS 12+
- Python 3.10+ (for building from source)

## Run from source

```bash
pip3 install rumps
python3 src/claude_tracker.py
```

## Build standalone .app

```bash
pip3 install rumps pyinstaller
./build.sh
# → dist/ClaudeTracker.app
```

Drag `ClaudeTracker.app` to `/Applications` and add it to **Login Items** in System Settings → General → Login Items.

## License

MIT
