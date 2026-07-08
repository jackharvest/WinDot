#!/bin/bash
# Builds WinDot.app and packages it into a distributable DMG with a custom
# background and a drag-to-Applications layout.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(plutil -extract CFBundleShortVersionString raw Info.plist)"
DMG_NAME="WinDot-${VERSION}.dmg"

./build.sh

rm -f "$DMG_NAME"

# dmgbuild (pure Python, writes .DS_Store directly) instead of create-dmg/Finder
# AppleScript automation — Finder on this macOS version silently drops "background
# picture" assignments to icon view options with no error.
python3 -m dmgbuild \
  -s scripts/dmg_settings.py \
  -D app=WinDot.app \
  -D background=scripts/dmg_background.png \
  -D icon=Resources/AppIcon.icns \
  "WinDot" "$DMG_NAME"

echo "Built $DMG_NAME"
