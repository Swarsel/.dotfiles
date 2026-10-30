{
  root,
  name,
  element-desktop,
  jq,
  kitty,
  socat,
  spotify-player,
  vesktop,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    kitty
    element-desktop
    vesktop
    spotify-player
    jq
    socat
  ];
  text = ''
    while :; do
        case ''${1:-} in
        -k | --kitty)
            cmd=(sh -c 'kitty --app-id kittyterm -T kittyterm -o confirm_os_window_close=0 zellij --config ${root "files/zellij/config-kittyterm.kdl"} attach --create kittyterm' '&')
            searchapp="kittyterm"
            searchelement="app_id"
            ;;
        -e | --element)
            cmd=(element-desktop)
            searchapp="Element"
            searchelement="title"
            ;;
        -d | --vesktop)
            cmd=(vesktop)
            searchapp="vesktop"
            searchelement="app_id"
            ;;
        -s | --spotifyplayer)
            cmd=(sh -c 'kitty --app-id spotifytui -T spotifytui -o confirm_os_window_close=0 spotify_player' '&')
            searchapp="spotifytui"
            searchelement="app_id"
            ;;
        *) break ;;
        esac
        shift
    done

    WIN_INFO=$(niri msg -j windows | jq -c --arg element "$searchelement" --arg search "$searchapp" 'first(.[] | select (.[$element] | test($search))) | { id, is_focused }')
    ID=$(echo "$WIN_INFO" | jq -r '.id // empty')

    if [ -z "$ID" ]; then
        niri msg action spawn -- "''${cmd[@]}"
    elif [ "$(echo "$WIN_INFO" | jq -r '.is_focused')" = true ]; then
        niri msg action move-window-to-workspace --window-id "$ID" --focus false stash
    else
        FOCUSED_WS=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused) | .id')
        jq -cn --argjson window "$ID" --argjson workspace "$FOCUSED_WS" '{ Action: { MoveWindowToWorkspace: { window_id: $window, reference: { Id: $workspace }, focus: true } } }' | socat - "UNIX-CONNECT:$NIRI_SOCKET" >/dev/null
        niri msg action focus-window --id "$ID"
    fi
  '';
}
