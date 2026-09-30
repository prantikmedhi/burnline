#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)}"
DIST="$ROOT/dist"
STAGE="$DIST/.stage"
APP="$STAGE/Burnline.app"
VOLUME="$STAGE/volume"
DMG="$DIST/Burnline-${VERSION}-macOS-universal.dmg"
CHECKSUM="$DMG.sha256"

rm -rf "$STAGE"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$VOLUME"

swift build -c release --arch arm64 --arch x86_64
BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
swift scripts/generate-icon.swift

cp "$BIN_DIR/Burnline" "$APP/Contents/MacOS/Burnline"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/Burnline.icns "$APP/Contents/Resources/Burnline.icns"

codesign --force --deep --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"

cp -R "$APP" "$VOLUME/Burnline.app"
ln -s /Applications "$VOLUME/Applications"

rm -f "$DMG" "$CHECKSUM"
hdiutil create \
    -volname "Burnline" \
    -srcfolder "$VOLUME" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$DMG"

(
    cd "$DIST"
    shasum -a 256 "$(basename "$DMG")" > "$(basename "$CHECKSUM")"
)
rm -rf "$STAGE"

printf 'Created %s\n' "$DMG"
printf 'Checksum %s\n' "$CHECKSUM"
