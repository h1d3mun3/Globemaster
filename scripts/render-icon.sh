#!/bin/bash
# Render the .icon bundle with Icon Composer's ictool. Usage: render-icon.sh <out-dir> [size]
set -euo pipefail
OUT=${1:?out dir}; SIZE=${2:-1024}
IC="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
mkdir -p "$OUT"
for r in Default Dark TintedLight TintedDark; do
  "$IC" Globemaster/Resources/Globemaster.icon --export-image --output-file "$OUT/$r-$SIZE.png" \
    --platform macOS --rendition "$r" --width "$SIZE" --height "$SIZE" --scale 1 >/dev/null
done
