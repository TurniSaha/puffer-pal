#!/usr/bin/env bash
# Builds "Puffer Pal.app" into mac/build/, ad-hoc signed.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product PufferPal
BIN="$(swift build -c release --show-bin-path)/PufferPal"
APP="build/Puffer Pal.app"
WORK="build/icon"

rm -rf "$APP" "$WORK"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$WORK/AppIcon.iconset"
cp "$BIN" "$APP/Contents/MacOS/PufferPal"
cp Resources/Info.plist "$APP/Contents/Info.plist"

swift scripts/make-icon.swift "$WORK/icon-1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$WORK/icon-1024.png" --out "$WORK/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d "$WORK/icon-1024.png" --out "$WORK/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$WORK/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep -s - "$APP"
codesign --verify "$APP"
echo "built $APP"
