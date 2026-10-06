#!/bin/bash
# Build mknb CLI + MKNB.app (arm64, ad-hoc signed)
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=build
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "==> building CLI: mknb"
swiftc -O -o "$BUILD/mknb" Sources/Shared/Backlight.swift Sources/CLI/main.swift
codesign -s - --force "$BUILD/mknb" 2>/dev/null || true

echo "==> building app binary: MKNB"
swiftc -O -target arm64-apple-macosx14.0 \
    -o "$BUILD/MKNBBin" Sources/Shared/Backlight.swift Sources/App/MKNBApp.swift

echo "==> assembling MKNB.app"
APP="$BUILD/MKNB.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$BUILD/MKNBBin" "$APP/Contents/MacOS/MKNB"
cp Info.plist "$APP/Contents/Info.plist"
for d in Resources/*.lproj; do
    cp -R "$d" "$APP/Contents/Resources/"
done
# embed the CLI inside the app for convenience
cp "$BUILD/mknb" "$APP/Contents/Resources/mknb"
codesign -s - --force --deep "$APP" 2>/dev/null || true

echo "==> zipping artifacts"
( cd "$BUILD" && zip -qry MKNB.app.zip MKNB.app && zip -qj mknb.zip mknb )

echo "==> done"
ls -la "$BUILD"
