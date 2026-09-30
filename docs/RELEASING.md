# Releasing Burnline

Burnline releases are distributed as a universal macOS DMG from GitHub Releases.

## Build the package

```sh
./scripts/package-dmg.sh
```

The script reads the version from `Resources/Info.plist`, builds both Apple silicon and Intel slices, creates an ad-hoc signed app bundle, and writes:

- `dist/Burnline-<version>-macOS-universal.dmg`
- `dist/Burnline-<version>-macOS-universal.dmg.sha256`

The DMG contains `Burnline.app` and an Applications shortcut.

## Verify before publishing

```sh
swift test
swift build -c release
hdiutil verify dist/Burnline-<version>-macOS-universal.dmg
```

Mount the DMG, run `codesign --verify --deep --strict` against the app inside it, verify both executable architectures with `lipo -archs`, and confirm the Applications shortcut is present. Never label an ad-hoc build as Developer ID signed or notarized.

## Publish

Create a tag matching `CFBundleShortVersionString` and attach both the DMG and SHA-256 file to a GitHub Release.

```sh
gh release create v<version> \
  dist/Burnline-<version>-macOS-universal.dmg \
  dist/Burnline-<version>-macOS-universal.dmg.sha256 \
  --title "Burnline <version>"
```

## Signing status

The current community build is ad-hoc signed and not notarized. A future Developer ID release must use a dedicated signing identity and pass Apple notarization before publication. Do not replace an existing certificate-backed app with an ad-hoc build during verification.
