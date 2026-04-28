{ self, name, writeShellApplication, emacs30-pgtk, kitty, jq, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ emacs30-pgtk kitty jq ];
  text = ''
    wait=0
    while :; do
        case ''${1:-} in
        -w | --wait)
            wait=1
            ;;
        *) break ;;
        esac
        shift
    done

    WIN_INFO=$(niri msg -j windows | jq '.[] | select(.app_id | test("kittyterm")) | { id, is_focused, workspace_id }')
    ID=$(echo "$WIN_INFO" | jq -r '.id // empty')

    if [ -n "$ID" ]; then
        niri msg action close-window --id "$ID"
        emacsclient -c -a "" "$@"
        niri msg action spawn -- sh -c 'kitty --app-id kittyterm -T kittyterm -o confirm_os_window_close=0 zellij --config ${self}/files/zellij/config-kittyterm.kdl attach --create kittyterm' '&'
    else
        if [[ $wait -eq 0 ]]; then
            emacsclient -n -c -a "" "$@"
        else
            emacsclient -c -a "" "$@"
        fi
    fi
  '';
}
