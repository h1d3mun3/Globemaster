#!/bin/bash
# Build a release DMG of Globemaster.
#
#   scripts/build-dmg.sh archive
#       Archive the app and open the archive in Xcode. In the Organizer, choose
#       Distribute App > Direct Distribution, which signs it with a Developer ID
#       and notarizes it, then export the app.
#
#   scripts/build-dmg.sh package path/to/Globemaster.app [--unsigned]
#       Check that the exported app is signed with a Developer ID and notarized,
#       then write build/Globemaster.dmg: the app and a link to /Applications.
#       --unsigned skips the checks, to try packaging an app built without
#       signing; that DMG is not for distribution.
set -euo pipefail

APP_NAME="Globemaster"
SCHEME="Globemaster"
BUILD_DIR="build"
DMG_DIR="$BUILD_DIR/dmg"
ARCHIVE="$BUILD_DIR/$APP_NAME.xcarchive"
OUTPUT_DMG="$BUILD_DIR/$APP_NAME.dmg"

usage() {
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 1
}

archive() {
    echo "==> Archiving..."
    rm -rf "$ARCHIVE"
    xcodebuild -scheme "$SCHEME" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -archivePath "$ARCHIVE" \
        archive
    echo "==> Opening the archive in Xcode..."
    open "$ARCHIVE"
    echo "In the Organizer: Distribute App > Direct Distribution, then export the app."
    echo "Then run: $0 package path/to/$APP_NAME.app"
}

package() {
    local app="${1:-}" unsigned="${2:-}"
    [[ -d "$app" ]] || usage

    if [[ "$unsigned" == "--unsigned" ]]; then
        echo "==> Skipping signing checks (--unsigned): do not distribute this DMG."
    else
        # Capture the output first: `grep -q` closing the pipe early would fail
        # the pipeline under pipefail.
        echo "==> Checking the signature..."
        codesign --verify --deep --strict "$app"
        local details
        details=$(codesign -dvv "$app" 2>&1)
        [[ "$details" == *"Authority=Developer ID Application"* ]] \
            || { echo "error: $app is not signed with a Developer ID" >&2; exit 1; }
        echo "==> Checking notarization..."
        details=$(spctl -a -vv "$app" 2>&1 || true)
        [[ "$details" == *"source=Notarized Developer ID"* ]] \
            || { echo "error: $app is not notarized" >&2; exit 1; }
    fi

    echo "==> Staging..."
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    cp -R "$app" "$DMG_DIR/$APP_NAME.app"
    ln -s /Applications "$DMG_DIR/Applications"

    echo "==> Creating DMG..."
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_DIR" \
        -ov \
        -format UDZO \
        "$OUTPUT_DMG"

    echo "==> Done: $OUTPUT_DMG"
    open "$BUILD_DIR"
}

case "${1:-}" in
    archive) archive ;;
    package) shift; package "$@" ;;
    *) usage ;;
esac
