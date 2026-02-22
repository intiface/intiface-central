#!/usr/bin/env bash
set -euo pipefail

# Create a macOS .dmg installer for Intiface Central.
#
# Prerequisites:
#   brew install create-dmg
#
# Usage: Place "Intiface Central.app" next to this script, then run:
#   ./scripts/create-dmg.sh
#
# Output: Intiface Central.dmg in the same directory as this script.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Intiface Central"
APP_PATH="${SCRIPT_DIR}/${APP_NAME}.app"
DMG_PATH="${SCRIPT_DIR}/${APP_NAME}.dmg"

# Validate that the .app bundle exists.
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: ${APP_NAME}.app not found in ${SCRIPT_DIR}."
  echo "Build the app first with: flutter build macos --release"
  echo "Then copy build/macos/Build/Products/Release/${APP_NAME}.app to ${SCRIPT_DIR}/"
  exit 1
fi

# Validate that create-dmg is installed.
if ! command -v create-dmg &>/dev/null; then
  echo "Error: create-dmg not found on PATH."
  echo "Install it: brew install create-dmg"
  exit 1
fi

# create-dmg will not overwrite an existing file.
if [[ -f "$DMG_PATH" ]]; then
  echo "Removing existing ${APP_NAME}.dmg..."
  rm "$DMG_PATH"
fi

echo "Creating ${APP_NAME}.dmg..."
create-dmg \
  --volname "$APP_NAME" \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "${APP_NAME}.app" 150 190 \
  --app-drop-link 450 190 \
  "$DMG_PATH" \
  "$APP_PATH"

echo "Created ${DMG_PATH}"
