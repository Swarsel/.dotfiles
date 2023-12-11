#!/bin/bash

STR=$(swaymsg -t get_tree | grep spotify)
if [ "$STR" == "" ]; then
    exec spotify & sleep 2
    exec swaymsg '[class="Spotify"]' scratchpad show
else
    exec swaymsg '[class="Spotify"]' scratchpad show
fi
exit 0
