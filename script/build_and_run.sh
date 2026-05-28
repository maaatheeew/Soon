#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Soon"
BUNDLE_ID="dev.codex.CalDot"
APP_VERSION="${APP_VERSION:-1.1}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-2}"
MIN_SYSTEM_VERSION="26.0"

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
ICON_BUILD_DIR="$DIST_DIR/icon-build"

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

  local partial_info
  partial_info="$ICON_BUILD_DIR/PartialInfo.plist"
  rm -rf "$ICON_BUILD_DIR"
  mkdir -p "$ICON_BUILD_DIR"

  xcrun actool \
    --compile "$ICON_BUILD_DIR" \
    --platform macosx \
    --minimum-deployment-target "$MIN_SYSTEM_VERSION" \
    --app-icon "$APP_NAME" \
    --output-partial-info-plist "$partial_info" \
    --standalone-icon-behavior all \
    "$ICON_SOURCE" >/dev/null

  cp "$ICON_BUILD_DIR/Assets.car" "$APP_RESOURCES/Assets.car"
  cp "$ICON_BUILD_DIR/Soon.icns" "$ICON_FILE"
}

build_icon

/usr/libexec/PlistBuddy -c "Clear dict" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string Soon" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconName string Soon" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Soon" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $APP_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $APP_BUILD_NUMBER" "$INFO_PLIST"
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
