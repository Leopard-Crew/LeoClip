#!/bin/sh
set -e

APP_NAME="LeoClip"
VERSION="0.5.0"
VOLUME_NAME="${APP_NAME} ${VERSION}"
DMG_NAME="${APP_NAME}-${VERSION}-Leopard-PPC.dmg"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/Release"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/${APP_NAME}-${VERSION}"

APP_PATH="$BUILD_DIR/${APP_NAME}.app"
DMG_PATH="$DIST_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"

echo "Preparing LeoClip DMG..."
echo "Root: $ROOT_DIR"
echo "Version: $VERSION"

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "Error: hdiutil not found."
    echo "DMG creation must be run on Mac OS X, not on Linux."
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found."
    echo "Build the Release target first:"
    echo "xcodebuild -project LeoClip.xcodeproj -target LeoClip -configuration Release -sdk macosx10.5 ARCHS=ppc ONLY_ACTIVE_ARCH=YES build"
    exit 1
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
mkdir -p "$DIST_DIR"

# Remove stale current-version artifacts before creating new ones.
rm -f "$DMG_PATH"
rm -f "$CHECKSUM_PATH"

cp -R "$APP_PATH" "$STAGE_DIR/"
cp "$ROOT_DIR/README.md" "$STAGE_DIR/"
cp "$ROOT_DIR/LICENSE" "$STAGE_DIR/"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: expected DMG was not created:"
    echo "$DMG_PATH"
    exit 1
fi

echo "Creating SHA-256 checksum..."

(
    cd "$DIST_DIR"
    shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
)

echo "Created:"
echo "$DMG_PATH"
echo "$CHECKSUM_PATH"
