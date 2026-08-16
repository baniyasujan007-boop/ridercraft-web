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
#   ./scripts/build_android.sh [apk|run|web]
#
# Examples:
#   GOOGLE_WEB_CLIENT_ID="<existing-web-client-id>" ./scripts/build_android.sh
#   ./scripts/build_android.sh apk                  # build release APK
#   GOOGLE_WEB_CLIENT_ID="..." ./scripts/build_android.sh web
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/ridercraft_mobile"
SERVER_ENV="$ROOT/server/.env"

CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}"
TARGET="${1:-apk}"

# --client-id=<id> takes precedence over the environment variable.
for arg in "$@"; do
  case "$arg" in
    --client-id=*)
      CLIENT_ID="${arg#--client-id=}"
      ;;
    run|apk|web)
      TARGET="$arg"
      ;;
    -h|--help)
      echo "Usage: $0 [apk|run|web] [--client-id=<id>]"
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

cd "$APP_DIR"

case "$TARGET" in
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
    echo "error: unknown target '$TARGET' (expected apk|run|web)" >&2
    exit 1
    ;;
esac