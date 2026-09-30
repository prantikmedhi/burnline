#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release
swift scripts/generate-icon.swift

APP="$HOME/Applications/Burnline.app"
pkill -x Burnline 2>/dev/null || true
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Burnline "$APP/Contents/MacOS/Burnline"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/Burnline.icns "$APP/Contents/Resources/Burnline.icns"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
open "$APP"
printf 'Installed %s
' "$APP"
