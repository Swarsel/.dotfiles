#!/bin/bash

STR=$(swaymsg -t get_tree | grep Element)
if [ "$STR" == "" ]; then
    exec element-desktop
    #exec swaymsg '[app_id=SchildiChat]' move container to scratchpad; scratchpad show
else
    exec swaymsg '[app_id=Element]' kill
fi
exit 0
