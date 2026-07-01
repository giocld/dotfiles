#!/bin/bash
SINK="@DEFAULT_AUDIO_SINK@"
PREV_VOL=""
PREV_MUTED=""

while true; do
    RAW=$(wpctl get-volume "$SINK" 2>/dev/null)
    CUR_VOL=$(echo "$RAW" | awk '{print $2}')
    CUR_MUTED=$(echo "$RAW" | grep -c "MUTED")

    if [ -n "$PREV_VOL" ] && [ "$CUR_VOL" != "$PREV_VOL" ]; then
        VOL_PCT=$(awk "BEGIN {printf \"%.0f\", $CUR_VOL * 100}")
        swayosd-client \
            --custom-message "$VOL_PCT%" \
            --custom-icon audio-speakers \
            --custom-progress "$CUR_VOL"
    fi

    if [ -n "$PREV_MUTED" ] && [ "$CUR_MUTED" != "$PREV_MUTED" ]; then
        swayosd-client --output-volume mute-toggle
    fi

    PREV_VOL="$CUR_VOL"
    PREV_MUTED="$CUR_MUTED"
    sleep 0.3
done
