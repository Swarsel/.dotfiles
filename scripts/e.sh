wait=0
while :; do
    case ${1:-} in
        -w|--wait) wait=1
                   ;;
        *) break
    esac
    shift
done

STR=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]) | select(.name == "__i3_scratch")' | grep kittyterm || true )
if [ "$STR" == "" ]; then
    swaymsg '[title="kittyterm"]' scratchpad show
    emacsclient -c -a "" "$@"
    swaymsg '[title="kittyterm"]' scratchpad show
else
    if [[ $wait -eq 0 ]]; then
        emacsclient -n -c -a "" "$@"
    else
        emacsclient -c -a "" "$@"
    fi
fi
