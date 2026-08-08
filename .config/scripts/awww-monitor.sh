#!/bin/bash

# Re-apply the awww wallpaper whenever the connected monitor set changes.
# awww only sets wallpapers on outputs present at apply-time; a monitor
# plugged in later shows black until the image is re-applied.

# Wait for niri IPC to be available
for i in $(seq 1 50); do
    if niri msg outputs >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

PREV_OUTPUTS=""
while true; do
    OUTPUTS=$(niri msg --json outputs 2>/dev/null | jq -c 'keys | sort')
    if [ -z "$OUTPUTS" ] || [ "$OUTPUTS" = "$PREV_OUTPUTS" ]; then
        sleep 2
        continue
    fi

    # Give awww a moment to notice the new output, then re-apply current image
    sleep 1
    IMAGE=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
    if [ -n "$IMAGE" ] && [ -f "$IMAGE" ]; then
        awww img "$IMAGE" -t none
    fi
    PREV_OUTPUTS="$OUTPUTS"
    sleep 2
done
