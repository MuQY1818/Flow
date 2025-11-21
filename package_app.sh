#!/bin/bash

APP_NAME="TomatoClock"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

echo "Building $APP_NAME..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

echo "Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Info.plist" "$APP_BUNDLE/Contents/"
cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

echo "Preparing DMG Source..."
rm -rf DMG_SOURCE
mkdir DMG_SOURCE
cp -R "$APP_BUNDLE" DMG_SOURCE/
ln -s /Applications DMG_SOURCE/Applications

echo "Creating DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder DMG_SOURCE -ov -format UDZO "$DMG_NAME"

echo "Cleaning up..."
rm -rf DMG_SOURCE

echo "Done! $DMG_NAME created."
