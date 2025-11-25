#!/bin/bash

VIDEOS_DIR="$HOME/filme-tati"

echo "Video Resolutions:"
echo "=================="

for video in "$VIDEOS_DIR"/*.mp4; do
    if [ -f "$video" ]; then
        filename=$(basename "$video")
        width=$(mdls -name kMDItemPixelWidth -raw "$video")
        height=$(mdls -name kMDItemPixelHeight -raw "$video")
        if [ "$width" != "(null)" ] && [ "$height" != "(null)" ]; then
            echo "$filename: ${width}x${height}"
        else
            echo "$filename: Unable to read"
        fi
    fi
done
