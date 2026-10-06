#!/bin/bash
# Build matataki CLI + Matataki.app (arm64, ad-hoc signed)
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=build
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "==> building CLI: matataki"
swiftc -O -o "$BUILD/matataki" Sources/Shared/Backlight.swift Sources/CLI/main.swift
codesign -s - --force "$BUILD/matataki" 2>/dev/null || true

echo "==> building app binary: Matataki"
swiftc -O -target arm64-apple-macosx14.0 \
    -o "$BUILD/MatatakiBin" Sources/Shared/Backlight.swift Sources/App/MatatakiApp.swift

echo "==> assembling Matataki.app"
APP="$BUILD/Matataki.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$BUILD/MatatakiBin" "$APP/Contents/MacOS/Matataki"
cp Info.plist "$APP/Contents/Info.plist"
for d in Resources/*.lproj; do
    cp -R "$d" "$APP/Contents/Resources/"
done
# embed the CLI inside the app for convenience
cp "$BUILD/matataki" "$APP/Contents/Resources/matataki"
codesign -s - --force --deep "$APP" 2>/dev/null || true

echo "==> zipping artifacts"
( cd "$BUILD" && zip -qry Matataki.app.zip Matataki.app && zip -qj matataki.zip matataki )

echo "==> done"
ls -la "$BUILD"
