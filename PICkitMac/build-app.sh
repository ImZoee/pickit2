#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
cd "$SCRIPT_DIR"

mkdir -p ".build/cache/clang"
export CLANG_MODULE_CACHE_PATH="$SCRIPT_DIR/.build/cache/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"
if [[ -z "${SDKROOT:-}" && -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
fi

swift build -c release --disable-sandbox

APP_DIR="$SCRIPT_DIR/dist/PICkit Mac.app"
CONTENTS_DIR="$APP_DIR/Contents"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp ".build/release/PICkitMac" "$CONTENTS_DIR/MacOS/PICkitMac"
cp "Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"

if [[ -x "$SCRIPT_DIR/../pk2cmd/pk2cmd" ]]; then
    cp "$SCRIPT_DIR/../pk2cmd/pk2cmd" "$CONTENTS_DIR/Resources/pk2cmd"
fi
if [[ -f "$SCRIPT_DIR/../pk2cmd/PK2DeviceFile.dat" ]]; then
    cp "$SCRIPT_DIR/../pk2cmd/PK2DeviceFile.dat" "$CONTENTS_DIR/Resources/PK2DeviceFile.dat"
fi

codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
