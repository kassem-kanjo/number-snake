#!/usr/bin/env bash
# Builds the Number Snake macOS app and screensaver using only Apple's Command Line Tools.
# Run from anywhere:  mac/build.sh        Output goes to mac/dist/ (git-ignored).
set -euo pipefail

VERSION="0.3.1"            # the one place the version number lives
MIN_MACOS="12.0"
APP_ID="com.kassemkanjo.numbersnake"
SAVER_ID="com.kassemkanjo.numbersnake.saver"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
INDEX="${INDEX_SRC:-$ROOT/index.html}"     # INDEX_SRC and DIST can be overridden for testing
DIST="${DIST:-$HERE/dist}"
WORK="$DIST/.work"
APP="$DIST/Number Snake.app"
SAVER="$DIST/Number Snake.saver"
COPYRIGHT="Copyright 2026 Kassem Kanjo. MIT licence."

# --- checks ------------------------------------------------------------------
for tool in swiftc lipo iconutil sips codesign ditto plutil xcrun; do
  command -v "$tool" >/dev/null || { echo "error: '$tool' not found. Install the Command Line Tools: xcode-select --install" >&2; exit 1; }
done
[ -f "$INDEX" ] || { echo "error: $INDEX not found" >&2; exit 1; }
SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk)"
[ -d "$SDK" ] || { echo "error: macOS SDK not found (run: xcode-select --install)" >&2; exit 1; }

echo "Number Snake $VERSION: building into $DIST"
rm -rf "$DIST"
mkdir -p "$WORK"

# Compile one Swift target for arm64 and x86_64 and join them into a single universal file.
# usage: build_universal <output> <swiftc args...>
build_universal() {
  local out="$1"; shift
  local archs=()
  for arch in arm64 x86_64; do
    swiftc -swift-version 5 -O -sdk "$SDK" -target "$arch-apple-macos$MIN_MACOS" "$@" -o "$out.$arch"
    archs+=("$out.$arch")
  done
  lipo -create "${archs[@]}" -output "$out"
  rm -f "${archs[@]}"
}

# --- icon --------------------------------------------------------------------
echo "- icon"
swiftc -O -sdk "$SDK" "$HERE/make-icon.swift" -o "$WORK/make-icon"
"$WORK/make-icon" "$WORK/png" >/dev/null
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
for pair in "16 icon_16x16" "32 icon_16x16@2x" "32 icon_32x32" "64 icon_32x32@2x" "128 icon_128x128" \
            "256 icon_128x128@2x" "256 icon_256x256" "512 icon_256x256@2x" "512 icon_512x512" "1024 icon_512x512@2x"; do
  set -- $pair
  cp "$WORK/png/icon_$1.png" "$ICONSET/$2.png"
done
iconutil -c icns "$ICONSET" -o "$WORK/AppIcon.icns"
cp "$WORK/png/icon_1024.png" "$HERE/icon.png"      # committed so it can be reviewed and reused

# --- app ---------------------------------------------------------------------
echo "- app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
build_universal "$APP/Contents/MacOS/NumberSnake" "$HERE/app/main.swift"
cp "$INDEX" "$APP/Contents/Resources/index.html"
cp "$WORK/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>NumberSnake</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>$APP_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Number Snake</string>
  <key>CFBundleDisplayName</key><string>Number Snake</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>NSHumanReadableCopyright</key><string>$COPYRIGHT</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSSupportsAutomaticTermination</key><false/>
</dict>
</plist>
EOF
plutil -lint "$APP/Contents/Info.plist" >/dev/null
codesign --force --deep -s - "$APP"

# --- screensaver -------------------------------------------------------------
echo "- screensaver"
mkdir -p "$SAVER/Contents/MacOS" "$SAVER/Contents/Resources"
build_universal "$SAVER/Contents/MacOS/NumberSnakeSaver" -emit-library -Xlinker -bundle \
  -module-name NumberSnakeSaver "$HERE/saver/NumberSnakeSaverView.swift"
cp "$INDEX" "$SAVER/Contents/Resources/index.html"
cp "$WORK/AppIcon.icns" "$SAVER/Contents/Resources/AppIcon.icns"
# The little picture System Settings may show in its list: the icon centred on the page's dark colour.
sips -z 116 116 "$WORK/png/icon_128.png" --out "$WORK/thumb.png" >/dev/null
sips --padToHeightWidth 116 180 --padColor 0B0B0C "$WORK/thumb.png" --out "$SAVER/Contents/Resources/thumbnail@2x.png" >/dev/null 2>&1
sips -z 58 90 "$SAVER/Contents/Resources/thumbnail@2x.png" --out "$SAVER/Contents/Resources/thumbnail.png" >/dev/null
cat > "$SAVER/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>NumberSnakeSaver</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>$SAVER_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Number Snake</string>
  <key>CFBundlePackageType</key><string>BNDL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
  <key>NSHumanReadableCopyright</key><string>$COPYRIGHT</string>
  <key>NSPrincipalClass</key><string>NumberSnakeSaverView</string>
</dict>
</plist>
EOF
plutil -lint "$SAVER/Contents/Info.plist" >/dev/null
codesign --force --deep -s - "$SAVER"

# --- zips for release (ditto keeps the bundle structure and signature intact) ---
echo "- zips"
ditto -c -k --keepParent "$APP"   "$DIST/Number-Snake-mac-app.zip"
ditto -c -k --keepParent "$SAVER" "$DIST/Number-Snake-screensaver.zip"
rm -rf "$WORK"

echo
echo "Done. Built version $VERSION (arm64 + x86_64, macOS $MIN_MACOS or newer, ad-hoc signed, not notarised):"
echo "  $APP"
echo "  $SAVER"
echo "  $DIST/Number-Snake-mac-app.zip"
echo "  $DIST/Number-Snake-screensaver.zip"
echo "  $HERE/icon.png"
