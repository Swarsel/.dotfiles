#!/bin/bash

swaymsg opacity plus 0.01

if [ $? -eq 0 ]; then
        # opacity was not 1, we toggle off
        swaymsg opacity 1
else
        # opacity was 1, we toggle on
        swaymsg opacity 0.95
fi
