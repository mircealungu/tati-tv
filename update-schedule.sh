#!/bin/bash
SHEET_URL=""
SCRIPT_DIR="$HOME/tati-tv"
VIDEOS_DIR="$HOME/filme-tati"
YTDLP="$HOME/yt-dlp"
SCHEDULE_CSV="$SCRIPT_DIR/schedule.csv"
CRON_FILE="$SCRIPT_DIR/tati-cron"
mkdir -p "$SCRIPT_DIR" "$VIDEOS_DIR"
echo "=== Tati TV Schedule Update ==="
echo "$(date)"
curl -sL "$SHEET_URL" -o "$SCHEDULE_CSV"
echo "" >> "$SCHEDULE_CSV"
if [ ! -s "$SCHEDULE_CSV" ]; then
    echo "ERROR: Failed to download schedule"
    exit 1
fi
echo "Schedule:"
cat "$SCHEDULE_CSV"
echo ""
crontab -l 2>/dev/null | grep -v "# tati-tv" > "$CRON_FILE"
echo "0 * * * * $SCRIPT_DIR/update-schedule.sh >> $SCRIPT_DIR/update.log 2>&1 # tati-tv" >> "$CRON_FILE"
tail -n +2 "$SCHEDULE_CSV" | while IFS=, read -r day time url title; do
    day=$(echo "$day" | tr -d '"' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    time=$(echo "$time" | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    url=$(echo "$url" | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/\\//g')
    title=$(echo "$title" | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    [ -z "$url" ] && continue
    
    echo "Processing: $title ($day @ $time)"
    
    # Get video ID
    if [[ "$url" == *"youtu.be"* ]]; then
        video_id=$(echo "$url" | sed 's|.*youtu.be/||' | cut -d'?' -f1)
    else
        video_id=$(echo "$url" | sed 's/.*v=//' | cut -d'&' -f1)
    fi
    
    # Build filename: ID + title (if present)
    if [ -n "$title" ]; then
        safe_title=$(echo "$title" | tr ' ' '-' | tr -cd '[:alnum:]-' | head -c 40)
        safe_name="${video_id}-${safe_title}"
    else
        safe_name="$video_id"
    fi
    video_file="$VIDEOS_DIR/${safe_name}.mp4"
    
    if [ ! -f "$video_file" ]; then
        echo "  Downloading..."
        "$YTDLP" "$url" -o "$video_file" -f "bestvideo[vcodec^=avc1][height<=1080]+bestaudio[ext=m4a]/best[vcodec^=avc1]" --no-warnings
    else
        echo "  Already have it"
    fi
    
    hour=$(echo "$time" | cut -d: -f1)
    minute=$(echo "$time" | cut -d: -f2)
    
    case "$day" in
        mon) dow=1 ;; tue) dow=2 ;; wed) dow=3 ;; thu) dow=4 ;;
        fri) dow=5 ;; sat) dow=6 ;; sun) dow=0 ;; *) dow="*" ;;
    esac
    
    echo "$minute $hour * * $dow /usr/local/bin/catt cast \"$video_file\" # tati-tv: $title" >> "$CRON_FILE"
done
crontab "$CRON_FILE"
echo ""
echo "Crontab updated:"
crontab -l | grep "tati-tv"

