#!/bin/bash
# Sync waybar visibility with niri overview state
# Hides waybar when overview opens, shows it when overview closes

# Wait for niri and waybar to be ready
sleep 5

# Make sure waybar is running before we start monitoring
while ! pgrep -x waybar > /dev/null; do
    sleep 1
done

# Monitor niri events and sync waybar visibility
niri msg event-stream 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" == *"Overview toggled: true"* ]]; then
        if pgrep -x waybar > /dev/null; then
            killall -SIGUSR1 waybar 2>/dev/null
        fi
    elif [[ "$line" == *"Overview toggled: false"* ]]; then
        if pgrep -x waybar > /dev/null; then
            killall -SIGUSR2 waybar 2>/dev/null
        fi
    fi
done
