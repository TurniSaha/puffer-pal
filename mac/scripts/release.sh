#!/usr/bin/env bash
# Builds the universal app and zips it for a GitHub Release: mac/build/Puffer-Pal-<version>.zip
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/bundle.sh --universal
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
ZIP="build/Puffer-Pal-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "build/Puffer Pal.app" "$ZIP"
echo "zipped $ZIP ($(lipo -archs "build/Puffer Pal.app/Contents/MacOS/PufferPal"))"
