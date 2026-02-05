{ self, name, writeShellApplication, kitty, element-desktop, vesktop, spotify-player, jq }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ kitty element-desktop vesktop spotify-player jq ];
  text = ''
    while :; do
        case ''${1:-} in
        -k | --kitty)
            cmd=(sh -c 'kitty --app-id kittyterm -T kittyterm -o confirm_os_window_close=0 zellij --config ${self}/files/zellij/config-kittyterm.kdl attach --create kittyterm' '&')
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

    if [ -z "$ID" ]; then
        niri msg action spawn -- "''${cmd[@]}"
    else
        niri msg action close-window --id "$ID"
    fi

  '';
}
