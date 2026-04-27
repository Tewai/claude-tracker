#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "🔨 Building Design A — Spark…"
pyinstaller --clean --noconfirm design_a.spec

echo ""
echo "🔨 Building Design B — Aura…"
pyinstaller --clean --noconfirm design_b.spec

echo ""
echo "✅ Done!"
echo "   Design A (Minimal):   dist/ClaudeTrackerSpark.app"
echo "   Design B (Dashboard): dist/ClaudeTrackerAura.app"
echo ""
echo "Run now:"
echo "   open dist/ClaudeTrackerSpark.app"
echo "   open dist/ClaudeTrackerAura.app"
