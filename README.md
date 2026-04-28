# Claude Pulse

macOS menu bar app for real-time Claude AI usage monitoring.  
Connects to the Claude.ai API and displays your session and weekly usage limits directly in the menu bar.

## Features

- **Menu bar display:** `⏱ 15% 📅 80%` — session and weekly usage at a glance
- **Color-coded status:** green (0–69 %) / orange (70–89 %) / red (90–100 %)
- **Detailed popup panel** with three metrics:
  - **Session** — 5-hour rolling usage window
  - **Weekly** — 7-day rolling usage window
  - **Sonnet** — separate Claude 3.5 Sonnet tracking (if available on your plan)
- Each metric shows percentage, visual progress bar, and countdown to reset
- Auto-refresh every 5 minutes + manual Refresh button
- Setup dialog for session cookie and org ID (stored securely in UserDefaults)

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

Claude Pulse authenticates using your browser session cookie. You only need to do this once.

1. Open [claude.ai](https://claude.ai) in your browser and log in
2. Open **DevTools** (`Cmd + Option + I`) → **Application** tab → **Cookies** → `https://claude.ai`
3. Find the cookie named `sessionKey` and copy its value
4. Click the `⏱` icon in your menu bar → **Setup**
5. Paste the cookie value into the **Session Cookie** field
6. Org ID is optional — the app resolves it automatically if left empty
7. Click **Save**

The app will immediately fetch your current usage data.

## Auto-launch at Login

To start Claude Pulse automatically when you log in:

**System Settings → General → Login Items → +** → select `ClaudePulse.app`

## Development

This project uses [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow):

```
main          ← stable / production (what users run)
feat/<name>   ← new features and experiments
fix/<name>    ← bug fixes
```

### Workflow for every change

```bash
# 1. Create a branch
git checkout -b feat/my-feature

# 2. Develop and test locally
./build_swift.sh
open dist/ClaudePulse.app

# 3. Commit
git add src/swift/ClaudePulse.swift build_swift.sh
git commit -m "feat: describe what and why"

# 4. Merge to main only after verifying the build works
git checkout main
git merge feat/my-feature

# 5. Push
git push origin main

# 6. Clean up
git branch -d feat/my-feature
```

**Never push directly to `main` without testing the build first.**

## License

MIT
