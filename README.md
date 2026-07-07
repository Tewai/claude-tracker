# Claude Pulse

macOS menu bar app for real-time Claude AI usage monitoring.  
Connects to the Claude.ai API and displays your session and weekly usage limits directly in the menu bar.

## Features

- **Menu bar display:** `⏱ 15% 📅 80% 📕 48%` — session, weekly, and Fable usage at a glance (Fable shows only if available on your plan)
- **Color-coded status:** green (0–69 %) / orange (70–89 %) / red (90–100 %)
- **Detailed popup panel** with five metrics:
  - **Session** — 5-hour rolling usage window
  - **Weekly** — 7-day rolling usage window
  - **Sonnet** — separate Sonnet tracking (if available on your plan)
  - **Fable** — separate Claude Fable 5 tracking (if available on your plan)
  - **Claude Design** — separate Claude Design tracking (if available on your plan)
- Each metric shows percentage, visual progress bar, and countdown to reset
- Auto-refresh every 5 minutes + manual Refresh button
- Setup dialog for session cookie and org ID (stored locally in UserDefaults)

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode Command Line Tools

Install Command Line Tools if not already present:

```bash
xcode-select --install
```

## Build & Install

```bash
./build_swift.sh
# → dist/ClaudePulse.app
```

Copy to Applications:

```bash
cp -r dist/ClaudePulse.app /Applications/
```

Launch the app:

```bash
open /Applications/ClaudePulse.app
```

## First-time Setup

Claude Pulse authenticates using the full cookie string from your browser session. You only need to do this once.

1. Open [claude.ai](https://claude.ai) in your browser and log in
2. Open **DevTools** (`Cmd + Option + I`) → **Network** tab
3. Reload the page, then click any request to `claude.ai`
4. In **Request Headers** find the `Cookie:` field — copy the entire value (long string starting with `sessionKey=sk-ant-…`)
5. Click the `⏱` icon in your menu bar to open the panel → click the **Cookie** button in the footer
6. Paste the full cookie string → click **Next →**
7. Paste your **Org ID** from the request URL (`/api/organizations/[THIS-ID]/usage`), or leave empty — the app resolves it automatically
8. Click **Save**

The app will immediately fetch your current usage data.

## Auto-launch at Login

To start Claude Pulse automatically when you log in:

**System Settings → General → Login Items → +** → select `ClaudePulse.app`
