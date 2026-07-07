#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

NAME="ClaudePulse"
BUNDLE_ID="com.claudepulse.app"
VERSION="1.2.1"
SRC="src/swift/${NAME}.swift"
APP="dist/${NAME}.app"

echo "🧹 Cleaning…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

echo "🔨 Compiling Swift…"
xcrun swiftc -O \
    -parse-as-library \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    "$SRC" \
    -o "$APP/Contents/MacOS/$NAME"

echo "🖼  Copying icon…"
cp "src/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "📋 Writing Info.plist…"
cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>      <string>${NAME}</string>
    <key>CFBundleIdentifier</key>     <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>           <string>${NAME}</string>
    <key>CFBundleDisplayName</key>    <string>Claude Pulse</string>
    <key>CFBundleVersion</key>        <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key>    <string>APPL</string>
    <key>LSMinimumSystemVersion</key> <string>14.0</string>
    <key>LSUIElement</key>            <true/>
    <key>CFBundleIconFile</key>         <string>AppIcon</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
</dict>
</plist>
PLIST

echo ""
echo "✅  dist/${NAME}.app"
echo ""
echo "Run:     open dist/${NAME}.app"
echo "Install: cp -r dist/${NAME}.app /Applications/"
