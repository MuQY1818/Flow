#!/bin/bash

ICON_SRC="logo_v2.svg.png"
ICONSET_DIR="TomatoClock.iconset"
mkdir -p "$ICONSET_DIR"

# Helper function to resize
resize() {
    size=$1
    out="$ICONSET_DIR/icon_${size}x${size}.png"
    sips -z $size $size "$ICON_SRC" --out "$out"
}

resize_2x() {
    size=$1
    doubled=$((size * 2))
    out="$ICONSET_DIR/icon_${size}x${size}@2x.png"
    sips -z $doubled $doubled "$ICON_SRC" --out "$out"
}

echo "Resizing icons..."
resize 16
resize_2x 16
resize 32
resize_2x 32
resize 128
resize_2x 128
resize 256
resize_2x 256
resize 512
resize_2x 512

# Copy original as 1024 (which is 512@2x)
cp "$ICON_SRC" "$ICONSET_DIR/icon_512x512@2x.png"

echo "Converting to icns..."
iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns

echo "Cleaning up..."
rm -rf "$ICONSET_DIR"
rm "$ICON_SRC"

echo "Icon generated: AppIcon.icns"
