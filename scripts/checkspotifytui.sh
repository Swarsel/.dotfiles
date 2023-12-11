#!/bin/bash
STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep spotifytui)
CHECK=$(swaymsg -t get_tree | grep spotifytui)
if [ "$CHECK" == "" ]; then
    exec kitty -T spotifytui -o confirm_os_window_close=0 spt & sleep 1
fi
if [ "$STR" == "" ]; then
    exec swaymsg '[title="spotifytui"]' scratchpad show
else
    exec swaymsg '[title="spotifytui"]' scratchpad show
fi
exit 0
