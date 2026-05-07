#!/bin/sh
set -e

APP_NAME="LeoClip"
EXPECTED_LOCALIZATION_COUNT=11

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/Release"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "LeoClip release check"
echo "Root: $ROOT_DIR"
echo

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "Error: hdiutil not found."
    echo "Release checks must be run on Mac OS X."
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Error: xcodebuild not found."
    exit 1
fi

cd "$ROOT_DIR"

echo "1. Cleaning build directory..."
rm -rf build

echo "2. Building Release target..."
xcodebuild -project LeoClip.xcodeproj \
    -target LeoClip \
    -configuration Release \
    -sdk macosx10.5 \
    ARCHS=ppc \
    ONLY_ACTIVE_ARCH=YES \
    build

if [ ! -d "$APP_PATH" ]; then
    echo "Error: expected app bundle was not created:"
    echo "$APP_PATH"
    exit 1
fi

echo "3. Running clipboard history smoke test..."
tools/smoke_test_history.sh

echo "4. Checking bundled Localizable.strings..."
LOCALIZABLE_COUNT="$(find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | wc -l | tr -d ' ')"

if [ "$LOCALIZABLE_COUNT" != "$EXPECTED_LOCALIZATION_COUNT" ]; then
    echo "Error: expected $EXPECTED_LOCALIZATION_COUNT Localizable.strings files, found $LOCALIZABLE_COUNT."
    find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | sort
    exit 1
fi

find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | sort

echo "5. Checking bundled InfoPlist.strings..."
INFOPLIST_COUNT="$(find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | wc -l | tr -d ' ')"

if [ "$INFOPLIST_COUNT" != "$EXPECTED_LOCALIZATION_COUNT" ]; then
    echo "Error: expected $EXPECTED_LOCALIZATION_COUNT InfoPlist.strings files, found $INFOPLIST_COUNT."
    find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | sort
    exit 1
fi

find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | sort

echo "6. Creating DMG..."
tools/make_dmg.sh

DMG_PATH="$(ls -1 "$ROOT_DIR"/dist/"$APP_NAME"-*-Leopard-PPC.dmg | tail -1)"
SHA_PATH="$DMG_PATH.sha256"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found."
    exit 1
fi

if [ ! -f "$SHA_PATH" ]; then
    echo "Error: SHA-256 file not found."
    exit 1
fi

echo "7. Verifying DMG..."
hdiutil verify "$DMG_PATH"

echo "8. SHA-256:"
cat "$SHA_PATH"

echo
echo "LeoClip release check passed."
echo "DMG: $DMG_PATH"
echo "SHA: $SHA_PATH"
