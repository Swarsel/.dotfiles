kitty=0
element=0
vesktop=0
spotifyplayer=0
while :; do
    case ${1:-} in
    -k | --kitty)
        kitty=1
        ;;
    -e | --element)
        element=1
        ;;
    -d | --vesktop)
        vesktop=1
        ;;
    -s | --spotifyplayer)
        spotifyplayer=1
        ;;
    *) break ;;
    esac
    shift
done

if [[ $kitty -eq 1 ]]; then
    STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep kittyterm || true)
    CHECK=$(swaymsg -t get_tree | grep kittyterm || true)
    if [ "$CHECK" == "" ]; then
        exec kitty --app-id kittyterm -T kittyterm -o confirm_os_window_close=0 zellij attach --create kittyterm &
        sleep 1
    fi
    if [ "$STR" == "" ]; then
        exec swaymsg '[title="kittyterm"]' scratchpad show
    else
        exec swaymsg '[title="kittyterm"]' scratchpad show
    fi
elif [[ $element -eq 1 ]]; then
    STR=$(swaymsg -t get_tree | grep Element || true)
    if [ "$STR" == "" ]; then
        exec element-desktop
    else
        exec swaymsg '[app_id=Element]' kill
    fi
elif [[ $vesktop -eq 1 ]]; then
    STR=$(swaymsg -t get_tree | grep vesktop || true)
    if [ "$STR" == "" ]; then
        exec vesktop
    else
        exec swaymsg '[app_id=vesktop]' kill
    fi
elif [[ $spotifyplayer -eq 1 ]]; then
    STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep spotifytui || true)
    CHECK=$(swaymsg -t get_tree | grep spotifytui || true)
    if [ "$CHECK" == "" ]; then
        exec kitty --add-id spotifytui -T spotifytui -o confirm_os_window_close=0 spotify_player &
        sleep 1
    fi
    if [ "$STR" == "" ]; then
        exec swaymsg '[title="spotifytui"]' scratchpad show
    else
        exec swaymsg '[title="spotifytui"]' scratchpad show
    fi
fi
