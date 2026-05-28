#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Soon"
BUNDLE_ID="dev.codex.CalDot"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_SOURCE="$ROOT_DIR/Assets/Soon.icon"
ICON_FILE="$APP_RESOURCES/Soon.icns"
ICON_TOOL="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"

for PROCESS_NAME in "$APP_NAME" "CalDot" "CalendarMenu"; do
  pkill -x "$PROCESS_NAME" >/dev/null 2>&1 || true
done

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

build_icon() {
  if [[ ! -d "$ICON_SOURCE" ]]; then
    return
  fi

  if [[ ! -x "$ICON_TOOL" ]]; then
    echo "warning: Icon Composer ictool not found; app icon will be skipped" >&2
    return
  fi

  local icon_build_dir iconset
  icon_build_dir="$DIST_DIR/icon-build"
  iconset="$icon_build_dir/Soon.iconset"
  rm -rf "$icon_build_dir"
  mkdir -p "$iconset"

  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_16x16.png" --platform macOS --rendition Default --width 16 --height 16 --scale 1 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_16x16@2x.png" --platform macOS --rendition Default --width 16 --height 16 --scale 2 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_32x32.png" --platform macOS --rendition Default --width 32 --height 32 --scale 1 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_32x32@2x.png" --platform macOS --rendition Default --width 32 --height 32 --scale 2 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_128x128.png" --platform macOS --rendition Default --width 128 --height 128 --scale 1 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_128x128@2x.png" --platform macOS --rendition Default --width 128 --height 128 --scale 2 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_256x256.png" --platform macOS --rendition Default --width 256 --height 256 --scale 1 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_256x256@2x.png" --platform macOS --rendition Default --width 256 --height 256 --scale 2 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_512x512.png" --platform macOS --rendition Default --width 512 --height 512 --scale 1 >/dev/null
  "$ICON_TOOL" "$ICON_SOURCE" --export-image --output-file "$iconset/icon_512x512@2x.png" --platform macOS --rendition Default --width 512 --height 512 --scale 2 >/dev/null
  iconutil -c icns "$iconset" -o "$ICON_FILE"
}

build_icon

/usr/libexec/PlistBuddy -c "Clear dict" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string Soon.icns" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Soon" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSCalendarsFullAccessUsageDescription string Soon shows upcoming Apple Calendar events in the menu bar." "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSCalendarsUsageDescription string Soon shows upcoming Apple Calendar events in the menu bar." "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass string NSApplication" "$INFO_PLIST"

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --package-only|package)
    echo "$APP_BUNDLE"
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package-only]" >&2
    exit 2
    ;;
esac
