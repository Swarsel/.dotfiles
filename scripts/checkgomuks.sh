#!/bin/bash
STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep gomuksterm)
CHECK=$(swaymsg -t get_tree | grep gomuksterm)
if [ "$CHECK" == "" ]; then
    exec kitty -T gomuksterm -o confirm_os_window_close=0 gomuks & sleep 1
fi
if [ "$STR" == "" ]; then
    exec swaymsg '[title="gomuksterm"]' scratchpad show
else
    exec swaymsg '[title="gomuksterm"]' scratchpad show
fi
exit 0
