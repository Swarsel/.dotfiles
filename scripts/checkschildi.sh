#!/bin/bash

STR=$(swaymsg -t get_tree | grep SchildiChat)
if [ "$STR" == "" ]; then
    exec schildichat-desktop
    #exec swaymsg '[app_id=SchildiChat]' move container to scratchpad; scratchpad show
else
    exec swaymsg '[app_id=SchildiChat]' kill
fi
exit 0
