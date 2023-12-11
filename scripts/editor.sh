#!/bin/bash

STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep kittyterm)
if [ "$STR" == "" ]; then
    VAR="1"
    swaymsg '[title="kittyterm"]' scratchpad show
else
    VAR="0"
fi
emacsclient -c -a "" "$@"
if [ "$VAR" == "1" ]
then
    swaymsg '[title="kittyterm"]' scratchpad show
fi
exit 0
