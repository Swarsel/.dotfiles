headless="false"
while [[ $# -gt 0 ]]; do
    case "$1" in
    -h)
        headless="true"
        ;;
    *)
        echo "Invalid option detected."
        ;;
    esac
    shift
done

SHARESCREEN="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$(hostname)".config.home-manager.users."$(whoami)".swarselsystems.sharescreen)"

if [[ $headless == "true" ]]; then
    wl-mirror "$SHARESCREEN"
else
    wl-mirror "$SHARESCREEN" &
    sleep 0.1
    swaymsg '[app_id=at.yrlf.wl_mirror] move to workspace 14:T'
    swaymsg '[app_id=at.yrlf.wl_mirror] fullscreen'
fi
