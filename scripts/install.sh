#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release
swift scripts/generate-icon.swift

APP="$HOME/Applications/Burnline.app"
pkill -x Burnline 2>/dev/null || true
for _ in {1..20}; do
    pgrep -x Burnline >/dev/null || break
    sleep 0.1
done
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Burnline "$APP/Contents/MacOS/Burnline"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/Burnline.icns "$APP/Contents/Resources/Burnline.icns"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
open -n "$APP"
printf 'Installed %s
' "$APP"
