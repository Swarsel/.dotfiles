while :; do
    case ${1:-} in
    -k | --kitty)
        cmd=(sh -c 'kitty --app-id kittyterm -T kittyterm -o confirm_os_window_close=0 zellij attach --create kittyterm' '&')
        searchapp="kittyterm"
        ;;
    -e | --element)
        cmd=(element-desktop)
        searchapp="Element"
        ;;
    -d | --vesktop)
        cmd=(vesktop)
        searchapp="vesktop"
        ;;
    -s | --spotifyplayer)
        cmd=(sh -c 'kitty --add-id spotifytui -T spotifytui -o confirm_os_window_close=0 spotify_player' '&')
        searchapp="spotifytui"
        ;;
    *) break ;;
    esac
    shift
done

WIN_INFO=$(niri msg -j windows | jq --arg search "$searchapp" '.[] | select (.app_id | test($search)) | { id, is_focused, workspace_id }')
ID=$(echo "$WIN_INFO" | jq -r '.id // empty')
IS_FOCUSED=$(echo "$WIN_INFO" | jq -r '.is_focused // empty')
TARGET_MONITOR=$(niri msg -j workspaces | jq --arg search "" '.[] | select (.name != null and (.name | test($search))) | { output }' | jq -r '.output // empty')
CURRENT_WORKSPACE=$(niri msg -j workspaces | jq -r '.[] | select (.is_active == true) | .output // empty')

if [ -z "$ID" ]; then
    niri msg action spawn -- "${cmd[@]}"
elif [ "$IS_FOCUSED" ]; then
    niri msg action move-window-to-workspace "" --window-id "$ID" --focus false
else
    niri msg action focus-monitor "$TARGET_MONITOR" && niri msg action move-window-to-workspace "$CURRENT_WORKSPACE" --window-id "$ID" && niri msg action focus-floating
fi
