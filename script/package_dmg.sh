#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Soon"
APP_VERSION="${APP_VERSION:-1.1}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_STAGING="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/$APP_NAME-$APP_VERSION.dmg"
DMG_LATEST_PATH="$DIST_DIR/$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME"

cd "$ROOT_DIR"
APP_VERSION="$APP_VERSION" APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-2}" "$ROOT_DIR/script/build_and_run.sh" --package-only

rm -rf "$DMG_STAGING" "$DMG_PATH" "$DMG_LATEST_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign --force --sign - "$DMG_PATH" >/dev/null
cp "$DMG_PATH" "$DMG_LATEST_PATH"

echo "$DMG_PATH"
