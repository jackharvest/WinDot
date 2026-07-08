#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="WinDot.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

swift build -c release
cp .build/release/WinDot "$APP/Contents/MacOS/WinDot"

codesign --force --deep --sign - "$APP"

echo "Built $APP"
