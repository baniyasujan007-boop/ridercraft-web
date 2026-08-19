#!/usr/bin/env bash
#
# Safe build helper for the RiderCraft Flutter Android app.
#
# Passes GOOGLE_WEB_CLIENT_ID to the Flutter build so Google Sign-In is
# configured. The value is read from the GOOGLE_WEB_CLIENT_ID environment
# variable (or the --client-id argument) and NEVER hardcoded, echoed, or
# committed. When omitted, it falls back to the GOOGLE_CLIENT_ID already
# present in server/.env so the app always reuses the working Web OAuth
# client — no new client is ever created.
#
# Usage:
#   ./scripts/build_android.sh [dev|apk|run|web]
#
# Examples:
#   ./scripts/build_android.sh dev                  # debug run vs production backend
#   ./scripts/build_android.sh apk                  # build release APK
#   ./scripts/build_android.sh run                  # debug run vs configured API
#   ./scripts/build_android.sh web                  # build web bundle
#
# `dev` is a one-command USB debug workflow:
#   - requires exactly one connected Android device (adb)
#   - runs `flutter run` in debug mode (hot reload)
#   - talks to the production backend on Render (no local backend required)
#   - never prints the OAuth client ID
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/ridercraft_mobile"
SERVER_ENV="$ROOT/server/.env"

# Production backend hosted on Render; the debug build talks straight to it.
PROD_BASE_URL="https://ridercraft-api.onrender.com"

CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}"
TARGET="${1:-apk}"

# --client-id=<id> takes precedence over the environment variable.
for arg in "$@"; do
  case "$arg" in
    --client-id=*)
      CLIENT_ID="${arg#--client-id=}"
      ;;
    dev|run|apk|web)
      TARGET="$arg"
      ;;
    -h|--help)
      echo "Usage: $0 [dev|apk|run|web] [--client-id=<id>]"
      echo "  Reads GOOGLE_WEB_CLIENT_ID from the environment by default."
      exit 0
      ;;
  esac
done

# Fall back to the Web OAuth client ID already used in production.
if [[ -z "$CLIENT_ID" && -f "$SERVER_ENV" ]]; then
  CLIENT_ID="$(sed -n 's/^GOOGLE_CLIENT_ID=//p' "$SERVER_ENV" | head -n 1)"
fi

if [[ -z "$CLIENT_ID" ]]; then
  echo "error: GOOGLE_WEB_CLIENT_ID is empty." >&2
  echo "  Set GOOGLE_WEB_CLIENT_ID in the environment, pass --client-id=<id>," >&2
  echo "  or ensure server/.env defines GOOGLE_CLIENT_ID." >&2
  exit 1
fi

# Requires exactly one connected Android device in the `device` state.
connected_device() {
  local out
  if ! command -v adb >/dev/null 2>&1; then
    echo "error: adb not found. Install the Android platform-tools." >&2
    exit 1
  fi
  out="$(adb devices 2>/dev/null | awk 'NR > 1 && $2 == "device" { print $1 }')"
  if [[ -z "$out" ]]; then
    echo "error: no connected Android device found." >&2
    echo "  Connect a physical device over USB (allow USB debugging) or start an emulator." >&2
    exit 1
  fi
  if [[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" -ne 1 ]]; then
    echo "error: more than one device is connected." >&2
    printf '  %s\n' "$out" >&2
    echo "  Disconnect extras or target one device, then retry." >&2
    exit 1
  fi
  printf '%s\n' "$out"
}

cd "$APP_DIR"

case "$TARGET" in
  dev)
    echo "Dev run (USB device + production backend on Render)..."
    DEVICE="$(connected_device)"
    echo "  device detected: $DEVICE"
    echo "  no local backend / no adb reverse (API is hosted on Render)"

    echo "  running debug build (hot reload) against ${PROD_BASE_URL}..."
    flutter run \
      --dart-define=ENV=prod \
      --dart-define=API_BASE_URL="${PROD_BASE_URL}" \
      --dart-define=GOOGLE_WEB_CLIENT_ID="$CLIENT_ID"
    ;;
  apk)
    echo "Building Android release APK (release signing = debug keystore)..."
    flutter build apk --release \
      --dart-define=GOOGLE_WEB_CLIENT_ID="$CLIENT_ID"
    ;;
  run)
    echo "Running on a connected device/emulator..."
    flutter run --dart-define=GOOGLE_WEB_CLIENT_ID="$CLIENT_ID"
    ;;
  web)
    echo "Building web bundle..."
    flutter build web --dart-define=GOOGLE_WEB_CLIENT_ID="$CLIENT_ID"
    ;;
  *)
    echo "error: unknown target '$TARGET' (expected dev|apk|run|web)" >&2
    exit 1
    ;;
esac
