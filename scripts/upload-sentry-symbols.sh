#!/usr/bin/env bash
set -euo pipefail

# Upload native debug symbols to Sentry after a release build.
#
# Required env vars (or set via ~/.sentryclirc / .sentryclirc):
#   SENTRY_AUTH_TOKEN - API auth token
#   SENTRY_ORG       - Organization slug
#   SENTRY_PROJECT   - Project slug
#
# Usage: ./scripts/upload-sentry-symbols.sh <platform>
#   platform: windows | linux | macos | ios | android

VALID_PLATFORMS="windows linux macos ios android"

usage() {
  echo "Usage: $0 <platform>"
  echo "  platform: ${VALID_PLATFORMS// / | }"
  echo ""
  echo "Environment variables (or use .sentryclirc):"
  echo "  SENTRY_AUTH_TOKEN  API auth token"
  echo "  SENTRY_ORG         Organization slug"
  echo "  SENTRY_PROJECT     Project slug"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

PLATFORM="$1"

# Validate platform argument.
if ! echo "$VALID_PLATFORMS" | grep -qw "$PLATFORM"; then
  echo "Error: Invalid platform '$PLATFORM'."
  echo "Valid platforms: ${VALID_PLATFORMS// / | }"
  exit 1
fi

# Check required env vars.
for var in SENTRY_AUTH_TOKEN SENTRY_ORG SENTRY_PROJECT; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $var is not set."
    echo "Set it as an environment variable or configure .sentryclirc."
    exit 1
  fi
done

# Check sentry-cli is available.
if ! command -v sentry-cli &>/dev/null; then
  echo "Error: sentry-cli not found on PATH."
  echo "Install it: https://docs.sentry.io/cli/installation/"
  exit 1
fi

# Resolve the debug symbol path for the given platform.
case "$PLATFORM" in
  windows)
    SYMBOL_PATH="build/windows/x64/runner/Release"
    ;;
  linux)
    SYMBOL_PATH="build/linux/x64/release/bundle"
    ;;
  macos)
    SYMBOL_PATH="build/macos/Build/Products/Release"
    ;;
  ios)
    SYMBOL_PATH="build/ios/Release-iphoneos"
    ;;
  android)
    SYMBOL_PATH="build/app/intermediates/merged_native_libs/release/out/lib"
    ;;
esac

if [[ ! -d "$SYMBOL_PATH" ]]; then
  echo "Error: Build output not found at '$SYMBOL_PATH'."
  echo "Run a release build for $PLATFORM first."
  exit 1
fi

echo "Uploading $PLATFORM debug symbols from $SYMBOL_PATH..."
sentry-cli debug-files upload --include-sources --wait "$SYMBOL_PATH"
echo "Debug symbol upload complete."

# Android: upload Proguard mapping if present.
if [[ "$PLATFORM" == "android" ]]; then
  MAPPING="build/app/outputs/mapping/release/mapping.txt"
  if [[ -f "$MAPPING" ]]; then
    echo "Uploading Proguard mapping..."
    sentry-cli upload-proguard --org "$SENTRY_ORG" --project "$SENTRY_PROJECT" "$MAPPING"
    echo "Proguard mapping upload complete."
  fi
fi
