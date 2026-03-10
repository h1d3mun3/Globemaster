#!/bin/bash
set -euo pipefail

APP_NAME="KanaCommand"
SCHEME="KanaCommand"
BUILD_DIR="build"
DMG_DIR="$BUILD_DIR/dmg"
OUTPUT_DMG="$BUILD_DIR/$APP_NAME.dmg"

echo "==> Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$DMG_DIR"

echo "==> Building..."
xcodebuild -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    DEVELOPMENT_TEAM="" \
    CODE_SIGNING_ALLOWED=NO

echo "==> Extracting app..."
cp -R "$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app" "$DMG_DIR/"

echo "==> Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

echo "==> Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$OUTPUT_DMG"

echo "==> Done: $OUTPUT_DMG"
open "$BUILD_DIR"
