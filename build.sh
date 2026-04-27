#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "🔨 Building ClaudeTracker.app …"

pyinstaller --clean --noconfirm claude_tracker.spec

echo ""
echo "✅ Done! App is at: dist/ClaudeTracker.app"
echo ""
echo "To install: drag dist/ClaudeTracker.app to /Applications"
echo "To run now: open dist/ClaudeTracker.app"
