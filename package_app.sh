#!/bin/bash

APP_NAME="Flow"
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

# Add background
mkdir DMG_SOURCE/.background
cp dmg_background.png DMG_SOURCE/.background/background.png

echo "Creating Temporary RW DMG..."
rm -f "Flow_rw.dmg"
hdiutil create -srcfolder DMG_SOURCE -volname "$APP_NAME" -fs HFS+ -format UDRW "Flow_rw.dmg"

echo "Mounting DMG..."
# Mount to a specific directory to ensure path consistency
mkdir -p /tmp/Flow_Mount
hdiutil attach "Flow_rw.dmg" -readwrite -noverify -noautoopen -mountpoint "/tmp/Flow_Mount"

echo "Configuring DMG View..."
# AppleScript to set background and icon positions
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:background.png"
        
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Force sync
sync

echo "Unmounting DMG..."
hdiutil detach "/tmp/Flow_Mount" -force

echo "Finalizing DMG..."
rm -f "$DMG_NAME"
hdiutil convert "Flow_rw.dmg" -format UDZO -o "$DMG_NAME"

echo "Cleaning up..."
rm -f "Flow_rw.dmg"
rm -rf DMG_SOURCE
rm -rf /tmp/Flow_Mount

echo "Done! $DMG_NAME created."
