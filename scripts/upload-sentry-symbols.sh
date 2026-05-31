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
  echo "sentry-cli not found on PATH; installing it for this job..."

  if ! command -v curl &>/dev/null; then
    echo "Error: curl is required to install sentry-cli."
    exit 1
  fi

  INSTALL_DIR="$(mktemp -d)"
  export INSTALL_DIR
  curl -sL https://sentry.io/get-cli/ | sh
  export PATH="$INSTALL_DIR:$PATH"

  if ! command -v sentry-cli &>/dev/null; then
    echo "Error: sentry-cli install completed, but sentry-cli is still not on PATH."
    exit 1
  fi
fi

# Resolve the debug symbol path for the given platform.
SYMBOL_PATHS=()
case "$PLATFORM" in
  windows)
    SYMBOL_PATHS=("build/windows/x64/runner/Release")
    ;;
  linux)
    SYMBOL_PATHS=("build/linux/x64/release/bundle")
    ;;
  macos)
    SYMBOL_PATHS=("build/macos/archive/Intiface Central.xcarchive/dSYMs")
    ;;
  ios)
    SYMBOL_PATHS=("build/ios/archive/Intiface Central.xcarchive/dSYMs")
    ;;
  android)
    SYMBOL_PATHS=("build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib")
    ;;
esac

EXISTING_SYMBOL_PATHS=()
for path in "${SYMBOL_PATHS[@]}"; do
  if [[ -d "$path" ]]; then
    EXISTING_SYMBOL_PATHS+=("$path")
  fi
done

if [[ "${#EXISTING_SYMBOL_PATHS[@]}" -eq 0 ]]; then
  echo "Error: Build output not found for $PLATFORM."
  printf 'Checked path: %s\n' "${SYMBOL_PATHS[@]}"
  echo "Run a release build for $PLATFORM first."
  exit 1
fi

echo "Uploading $PLATFORM debug symbols..."
printf '  %s\n' "${EXISTING_SYMBOL_PATHS[@]}"
sentry-cli debug-files upload \
  --org "$SENTRY_ORG" \
  --project "$SENTRY_PROJECT" \
  --include-sources \
  --wait \
  "${EXISTING_SYMBOL_PATHS[@]}"
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
