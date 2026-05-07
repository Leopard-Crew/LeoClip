#!/bin/sh
set -e

APP_NAME="LeoClip"
VERSION="0.4.1"
VOLUME_NAME="${APP_NAME} ${VERSION}"
DMG_NAME="${APP_NAME}-${VERSION}-Leopard-PPC.dmg"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/Release"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/${APP_NAME}-${VERSION}"

APP_PATH="$BUILD_DIR/${APP_NAME}.app"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "Preparing LeoClip DMG..."
echo "Root: $ROOT_DIR"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found."
    echo "Build the Release target first:"
    echo "xcodebuild -project LeoClip.xcodeproj -target LeoClip -configuration Release -sdk macosx10.5 ARCHS=ppc ONLY_ACTIVE_ARCH=YES build"
    exit 1
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
mkdir -p "$DIST_DIR"

cp -R "$APP_PATH" "$STAGE_DIR/"
cp "$ROOT_DIR/README.md" "$STAGE_DIR/"
cp "$ROOT_DIR/LICENSE" "$STAGE_DIR/"

rm -f "$DMG_PATH"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Created:"
echo "$DMG_PATH"
