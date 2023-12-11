#!/bin/bash

STR=$(swaymsg -t get_tree | grep discord)
if [ "$STR" == "" ]; then
    exec discord
    #exec swaymsg '[class=discord]' move container to scratchpad; scratchpad show
else
    exec swaymsg '[app_id=discord]' kill
fi
exit 0
