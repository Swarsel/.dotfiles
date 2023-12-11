#!/bin/bash

STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep kittyterm)
CHECK=$(swaymsg -t get_tree | grep kittyterm)
if [ "$CHECK" == "" ]; then
    exec kitty -T kittyterm & sleep 1
fi
if [ "$STR" == "" ]; then
    exec swaymsg '[title="kittyterm"]' scratchpad show
else
    exec swaymsg '[title="kittyterm"]' scratchpad show
fi
exit 0
