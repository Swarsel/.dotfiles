STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep kittyterm || true )
if [ "$STR" == "" ]; then
    VAR="1"
    swaymsg '[title="kittyterm"]' scratchpad show
else
    VAR="0"
fi
emacsclient -c -a "" "$@" # open emacs in a new frame, start new daemon if it is dead and open arg
if [ "$VAR" == "1" ]
then
    swaymsg '[title="kittyterm"]' scratchpad show
fi
exit 0
