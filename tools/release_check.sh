#!/bin/sh
set -e

APP_NAME="LeoClip"
EXPECTED_LOCALIZATION_COUNT=11

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/Release"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
INFO_PLIST="$ROOT_DIR/Info.plist"
DMG_SCRIPT="$ROOT_DIR/tools/make_dmg.sh"
README_PATH="$ROOT_DIR/README.md"
PLISTBUDDY="/usr/libexec/PlistBuddy"

fail()
{
    echo "Error: $1"
    exit 1
}

require_command()
{
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "$1 not found."
    fi
}

echo "LeoClip release check"
echo "Root: $ROOT_DIR"
echo

require_command hdiutil
require_command xcodebuild
require_command plutil

if [ ! -x "$PLISTBUDDY" ]; then
    fail "PlistBuddy not found at $PLISTBUDDY."
fi

cd "$ROOT_DIR"

COMMIT_SHORT="unknown"
COMMIT_FULL="unknown"

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    COMMIT_SHORT="$(git rev-parse --short HEAD)"
    COMMIT_FULL="$(git rev-parse HEAD)"
fi

echo "Commit: $COMMIT_SHORT"
echo

echo "1. Checking Git working tree..."
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_STATUS="$(git status --porcelain --untracked-files=normal)"

    if [ -n "$GIT_STATUS" ] && [ "$ALLOW_DIRTY" != "1" ]; then
        echo "$GIT_STATUS"
        fail "working tree is not clean. Commit or discard changes first. Use ALLOW_DIRTY=1 only while testing the release script itself."
    fi

    if [ -n "$GIT_STATUS" ]; then
        echo "Warning: working tree is dirty, but ALLOW_DIRTY=1 is set."
        echo "$GIT_STATUS"
    else
        echo "Git working tree is clean."
    fi
else
    echo "Warning: not inside a Git working tree or git not available."
fi

echo "2. Checking versions..."
INFO_VERSION="$("$PLISTBUDDY" -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
SCRIPT_VERSION="$(sed -n 's/^VERSION="\([^"]*\)".*/\1/p' "$DMG_SCRIPT" | head -1)"

if [ -z "$INFO_VERSION" ]; then
    fail "could not read CFBundleShortVersionString from Info.plist."
fi

if [ -z "$SCRIPT_VERSION" ]; then
    fail "could not read VERSION from tools/make_dmg.sh."
fi

echo "Info.plist version: $INFO_VERSION"
echo "DMG script version: $SCRIPT_VERSION"

if [ "$INFO_VERSION" != "$SCRIPT_VERSION" ]; then
    fail "Info.plist version and DMG script version do not match."
fi

VERSION="$INFO_VERSION"

if [ "$REQUIRE_TAG" = "1" ]; then
    EXPECTED_TAG="v$VERSION"

    if ! command -v git >/dev/null 2>&1 || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        fail "REQUIRE_TAG=1 was set, but git is not available or this is not a Git working tree."
    fi

    if ! git tag --points-at HEAD | grep -x "$EXPECTED_TAG" >/dev/null 2>&1; then
        echo "Tags on HEAD:"
        git tag --points-at HEAD
        fail "HEAD is not tagged as $EXPECTED_TAG."
    fi

    echo "Release tag verified: $EXPECTED_TAG"
fi

EXPECTED_DMG="$ROOT_DIR/dist/$APP_NAME-$VERSION-Leopard-PPC.dmg"
EXPECTED_SHA="$EXPECTED_DMG.sha256"

echo "3. Checking README screenshot..."
SCREENSHOT_PATH="$(sed -n 's/.*<img src="\([^"]*\)".*/\1/p' "$README_PATH" | head -1)"

if [ -z "$SCREENSHOT_PATH" ]; then
    fail "README does not contain a local screenshot img src."
fi

case "$SCREENSHOT_PATH" in
    http://*|https://*)
        fail "README screenshot must be a local repository file, not a remote URL."
        ;;
esac

if [ ! -f "$ROOT_DIR/$SCREENSHOT_PATH" ]; then
    fail "README screenshot file not found: $SCREENSHOT_PATH"
fi

echo "README screenshot: $SCREENSHOT_PATH"

echo "4. Linting plist and strings files..."
plutil -lint "$INFO_PLIST"

for STRINGS_FILE in ./*.lproj/InfoPlist.strings ./*.lproj/Localizable.strings; do
    plutil -lint "$STRINGS_FILE"
done

echo "5. Cleaning build directory..."
rm -rf build

echo "6. Building Release target..."
xcodebuild -project LeoClip.xcodeproj \
    -target LeoClip \
    -configuration Release \
    -sdk macosx10.5 \
    ARCHS=ppc \
    ONLY_ACTIVE_ARCH=YES \
    build

if [ ! -d "$APP_PATH" ]; then
    fail "expected app bundle was not created: $APP_PATH"
fi

BUILT_VERSION="$("$PLISTBUDDY" -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")"

if [ "$BUILT_VERSION" != "$VERSION" ]; then
    fail "built app bundle version '$BUILT_VERSION' does not match release version '$VERSION'."
fi

echo "Built app bundle version: $BUILT_VERSION"

echo "7. Running clipboard history smoke test..."
tools/smoke_test_history.sh

echo "8. Checking bundled Localizable.strings..."
LOCALIZABLE_COUNT="$(find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | wc -l | tr -d ' ')"

if [ "$LOCALIZABLE_COUNT" != "$EXPECTED_LOCALIZATION_COUNT" ]; then
    echo "Found Localizable.strings files:"
    find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | sort
    fail "expected $EXPECTED_LOCALIZATION_COUNT Localizable.strings files, found $LOCALIZABLE_COUNT."
fi

find "$APP_PATH/Contents/Resources" -name Localizable.strings -print | sort

echo "9. Checking bundled InfoPlist.strings..."
INFOPLIST_COUNT="$(find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | wc -l | tr -d ' ')"

if [ "$INFOPLIST_COUNT" != "$EXPECTED_LOCALIZATION_COUNT" ]; then
    echo "Found InfoPlist.strings files:"
    find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | sort
    fail "expected $EXPECTED_LOCALIZATION_COUNT InfoPlist.strings files, found $INFOPLIST_COUNT."
fi

find "$APP_PATH/Contents/Resources" -name InfoPlist.strings -print | sort

echo "10. Creating DMG..."
tools/make_dmg.sh

if [ ! -f "$EXPECTED_DMG" ]; then
    fail "expected DMG not found: $EXPECTED_DMG"
fi

if [ ! -f "$EXPECTED_SHA" ]; then
    fail "expected SHA-256 file not found: $EXPECTED_SHA"
fi

SHA_NAME="$(awk '{print $2}' "$EXPECTED_SHA")"
EXPECTED_DMG_NAME="$(basename "$EXPECTED_DMG")"

if [ "$SHA_NAME" != "$EXPECTED_DMG_NAME" ]; then
    fail "SHA-256 file references '$SHA_NAME', expected '$EXPECTED_DMG_NAME'."
fi

echo "11. Verifying DMG..."
hdiutil verify "$EXPECTED_DMG"

echo "12. SHA-256:"
cat "$EXPECTED_SHA"

echo
echo "LeoClip release check passed."
echo "Version: $VERSION"
echo "Commit: $COMMIT_SHORT"
echo "DMG: $EXPECTED_DMG"
echo "SHA: $EXPECTED_SHA"
