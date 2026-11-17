#!/usr/bin/env bash
# Builds "Puffer Pal.app" into mac/build/, ad-hoc signed.
# --universal builds for both Apple silicon and Intel (for downloads); default is this Mac only.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--universal" ]]; then
  for arch in arm64 x86_64; do swift build -c release --product PufferPal --arch "$arch"; done
  BIN="build/PufferPal-universal"
  mkdir -p build
  lipo -create -output "$BIN" \
    "$(swift build -c release --arch arm64 --show-bin-path)/PufferPal" \
    "$(swift build -c release --arch x86_64 --show-bin-path)/PufferPal"
else
  swift build -c release --product PufferPal
  BIN="$(swift build -c release --show-bin-path)/PufferPal"
fi
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
