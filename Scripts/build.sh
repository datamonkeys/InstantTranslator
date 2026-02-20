#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="InstantTranslator"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"

echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - \
    --entitlements "Resources/InstantTranslator.entitlements" \
    "${APP_BUNDLE}"

echo ""
echo "Build complete! Run with:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "Or install to Applications:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
