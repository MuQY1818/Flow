#!/bin/bash

APP_NAME="Flow"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
BACKGROUND_IMAGE="dmg_background.png"
MAX_WINDOW_WIDTH=760
MAX_WINDOW_HEIGHT=480
FLOW_X_RATIO=0.14
APP_X_RATIO=0.86
ICON_Y_RATIO=0.49
MOUNT_POINT="/Volumes/$APP_NAME"

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

# Calculate background/window dimensions
BG_WIDTH=$(sips -g pixelWidth "$BACKGROUND_IMAGE" | awk 'NR==2 {print $2}')
BG_HEIGHT=$(sips -g pixelHeight "$BACKGROUND_IMAGE" | awk 'NR==2 {print $2}')

export BG_WIDTH BG_HEIGHT MAX_WINDOW_WIDTH MAX_WINDOW_HEIGHT FLOW_X_RATIO APP_X_RATIO ICON_Y_RATIO
python_output=$(python3 - <<'PY'
import os, math

width = int(os.environ['BG_WIDTH'])
height = int(os.environ['BG_HEIGHT'])
max_w = int(os.environ['MAX_WINDOW_WIDTH'])
max_h = int(os.environ['MAX_WINDOW_HEIGHT'])
flow_ratio = float(os.environ['FLOW_X_RATIO'])
app_ratio = float(os.environ['APP_X_RATIO'])
icon_y_ratio = float(os.environ['ICON_Y_RATIO'])

scale = 1.0
if width > max_w:
    scale = min(scale, max_w / width)
if height > max_h:
    scale = min(scale, max_h / height)
if scale == 0:
    scale = 1.0

target_w = max(400, round(width * scale))
target_h = max(300, round(height * scale))

flow_x = round(target_w * flow_ratio)
flow_y = round(target_h * icon_y_ratio)
app_x = round(target_w * app_ratio)
app_y = flow_y

print(target_w, target_h, flow_x, flow_y, app_x, app_y, scale)
PY
)
IFS=' ' read -r WINDOW_WIDTH WINDOW_HEIGHT FLOW_ICON_X FLOW_ICON_Y APPLICATION_ICON_X APPLICATION_ICON_Y SCALE <<< "$python_output"

WINDOW_LEFT=400
WINDOW_TOP=120
WINDOW_RIGHT=$((WINDOW_LEFT + WINDOW_WIDTH))
WINDOW_BOTTOM=$((WINDOW_TOP + WINDOW_HEIGHT))

# Add background (scaled if necessary)
mkdir DMG_SOURCE/.background
if [[ "$SCALE" != "1.0" && "$SCALE" != "1" ]]; then
    sips -z "$WINDOW_HEIGHT" "$WINDOW_WIDTH" "$BACKGROUND_IMAGE" --out DMG_SOURCE/.background/background.png >/dev/null
else
    cp "$BACKGROUND_IMAGE" DMG_SOURCE/.background/background.png
fi

echo "Creating Temporary RW DMG..."
rm -f "Flow_rw.dmg"
hdiutil create -srcfolder DMG_SOURCE -volname "$APP_NAME" -fs HFS+ -format UDRW "Flow_rw.dmg"

echo "Mounting DMG..."
# Ensure previous mounts are cleared
if [ -d "$MOUNT_POINT" ]; then
    hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
fi
mkdir -p "$MOUNT_POINT"
hdiutil attach "Flow_rw.dmg" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_POINT"

# Let Finder register the new volume
sleep 1
open "$MOUNT_POINT" >/dev/null 2>&1

echo "Configuring DMG View..."
# AppleScript to set background and icon positions
osascript <<EOF
set diskName to "$APP_NAME"
set mountPath to POSIX file "$MOUNT_POINT" as alias
set retries to 0
set windowBounds to {$WINDOW_LEFT, $WINDOW_TOP, $WINDOW_RIGHT, $WINDOW_BOTTOM}
set flowPosition to {$FLOW_ICON_X, $FLOW_ICON_Y}
set applicationsPosition to {$APPLICATION_ICON_X, $APPLICATION_ICON_Y}
tell application "Finder"
    open mountPath
    repeat until (exists disk diskName) or retries > 40
        delay 0.5
        set retries to retries + 1
    end repeat
    if not (exists disk diskName) then
        error "Disk " & diskName & " not mounted"
    end if
    tell disk diskName
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to windowBounds
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:background.png"
        
        set position of item "$APP_NAME.app" of container window to flowPosition
        set position of item "Applications" of container window to applicationsPosition
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Force sync
sync

echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -force

echo "Finalizing DMG..."
rm -f "$DMG_NAME"
hdiutil convert "Flow_rw.dmg" -format UDZO -o "$DMG_NAME"

echo "Cleaning up..."
rm -f "Flow_rw.dmg"
rm -rf DMG_SOURCE
rm -rf "$MOUNT_POINT"

echo "Done! $DMG_NAME created."
