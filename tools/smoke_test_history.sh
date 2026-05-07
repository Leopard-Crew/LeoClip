#!/bin/sh
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/tests"
TEST_BIN="$BUILD_DIR/LCClipboardHistorySmoke"

mkdir -p "$BUILD_DIR"

gcc-4.0 \
    -arch ppc \
    -isysroot /Developer/SDKs/MacOSX10.5.sdk \
    -mmacosx-version-min=10.5 \
    -I"$ROOT_DIR/Source/LeoClip" \
    "$ROOT_DIR/tests/LCClipboardHistorySmoke.m" \
    "$ROOT_DIR/Source/LeoClip/LCClipboardHistory.m" \
    -framework Foundation \
    -o "$TEST_BIN"

"$TEST_BIN"
