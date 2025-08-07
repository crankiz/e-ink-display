#!/usr/bin/env bash

# === DEFAULT CONFIGURATION ===
SSID="GuestSSID"
PASSWORD="WPApassword"
HEADER_TEXT="Guest WiFi Access"
SUBTEXT="Scan to connect"
ICON_IMG="icon_wifi.png"
OUTPUT="eink_display.png"
MONOCHROME=false

# Fonts (ensure they’re installed or adjust names)
FONT_HEADER="Montserrat-Bold"
FONT_SUBTEXT="Lato-Semibold"

# Output sizes
DISPLAY_WIDTH=400
DISPLAY_HEIGHT=300
QR_SIZE=180
ICON_HEIGHT=160
RIGHT_BLOCK_WIDTH=200
BOTTOM_TEXT_HEIGHT=30

# Temp files
QR_IMG="qr.png"
HEADER_IMG="header.png"
SUBTEXT_IMG="subtext.png"
ICON_RESIZED="icon_resized.png"
RIGHT_STACKED="right_stack.png"
MERGED_COLUMNS="columns.png"
FINAL_IMG="final.png"

# === ARGUMENT PARSING ===
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--header) HEADER_TEXT="$2"; shift ;;
        -p|--pass) PASSWORD="$2"; shift ;;
        -s|--ssid) SSID="$2"; shift ;;
        -t|--text) SUBTEXT="$2"; shift ;;
        -i|--image) ICON_IMG="$2"; shift ;;
        -o|--output) OUTPUT="$2"; shift ;;
        -m|--monochrome) MONOCHROME=true ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "  -h, --header      Header text"
            echo "  -p, --pass        WiFi password"
            echo "  -s, --ssid        WiFi SSID"
            echo "  -t, --text        Bottom subtext"
            echo "  -i, --image       Logo/image path"
            echo "  -o, --output      Output image filename"
            echo "  -m, --monochrome  Output image in black and white (e-paper ready)"
            echo "  --help            Show this help"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
    shift
done

# === Step 1: Generate QR Code ===
qrencode -o "$QR_IMG" "WIFI:S:$SSID;T:WPA;P:$PASSWORD;;" -s 10 -m 2
convert "$QR_IMG" -resize ${QR_SIZE}x${QR_SIZE} "$QR_IMG"

# === Step 2: Resize and turn black to gray in the icon image ===
convert "$ICON_IMG" -resize x${ICON_HEIGHT} +level-colors gray "$ICON_RESIZED"

# === Step 3: Vertically center the icon in right stack ===
convert -size ${RIGHT_BLOCK_WIDTH}x${DISPLAY_HEIGHT} canvas:none \
    -gravity Center "$ICON_RESIZED" -composite "$RIGHT_STACKED"

# === Step 4: Vertically center QR to match height ===
convert -size ${QR_SIZE}x${DISPLAY_HEIGHT} canvas:none \
    -gravity Center "$QR_IMG" -composite "$QR_IMG"

# === Step 5: Merge QR + right stack side by side ===
convert +append "$QR_IMG" "$RIGHT_STACKED" "$MERGED_COLUMNS"

# === Step 6: Create header text ===
convert -size ${DISPLAY_WIDTH}x50 canvas:none \
    -gravity Center -font "$FONT_HEADER" -pointsize 28 -fill black \
    -annotate +0+0 "$HEADER_TEXT" \
    "$HEADER_IMG"

# === Step 7: Create bottom subtext ===
convert -size ${DISPLAY_WIDTH}x${BOTTOM_TEXT_HEIGHT} canvas:none \
    -gravity Center -font "$FONT_SUBTEXT" -pointsize 24 -fill black \
    -annotate +0+0 "$SUBTEXT" \
    "$SUBTEXT_IMG"

# === Step 8: Create final canvas and place all components ===
convert -size ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} canvas:white "$FINAL_IMG"
composite -gravity North -geometry +0+10 "$HEADER_IMG" "$FINAL_IMG" "$FINAL_IMG"
composite -gravity Center -geometry +0+10 "$MERGED_COLUMNS" "$FINAL_IMG" "$FINAL_IMG"
composite -gravity South -geometry +0+10 "$SUBTEXT_IMG" "$FINAL_IMG" "$FINAL_IMG"

# === Step 9: Optionally convert to black-and-white ===
if $MONOCHROME; then
    convert "$FINAL_IMG" -monochrome "$OUTPUT"
else
    cp "$FINAL_IMG" "$OUTPUT"
fi

# === Cleanup ===
rm "$QR_IMG" "$HEADER_IMG" "$SUBTEXT_IMG" "$ICON_RESIZED" "$RIGHT_STACKED" "$MERGED_COLUMNS" "$FINAL_IMG"

echo "✅ Final image created: $OUTPUT"
