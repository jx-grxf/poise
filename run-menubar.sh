#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Poise"
SCHEME="Poise"
DERIVED=".build/DerivedData"

pkill -x "$APP_NAME" 2>/dev/null || true

if [ ! -d "$APP_NAME.xcodeproj" ]; then
  TUIST_SKIP_UPDATE_CHECK=1 tuist install
  TUIST_SKIP_UPDATE_CHECK=1 tuist generate --no-open
fi

TUIST_SKIP_UPDATE_CHECK=1 tuist xcodebuild build \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  > build.log 2>&1 || { tail -40 build.log; exit 1; }

APP_PATH="$DERIVED/Build/Products/Debug/$APP_NAME.app"
open "$APP_PATH"
echo "Launched $APP_PATH"
