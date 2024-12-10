SHARESCREEN="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$(hostname)".config.home-manager.users."$(whoami)".swarselsystems.sharescreen)"

touch /tmp/screenshare.state
STATE=$(< /tmp/screenshare.state)

if [[ $STATE != "1" ]]; then
    wl-mirror "$SHARESCREEN" &
    sleep 0.1
    swaymsg output "$SHARESCREEN" mode "$SWARSEL_LO_RES"
    echo 1 > /tmp/screenshare.state
    swaymsg '[app_id=at.yrlf.wl_mirror] move to workspace 12:S'
    swaymsg '[app_id=at.yrlf.wl_mirror] fullscreen'
else
    swaymsg output "$SHARESCREEN" mode "$SWARSEL_HI_RES"
    echo 0 > /tmp/screenshare.state
    swaymsg '[app_id=at.yrlf.wl_mirror] kill'
fi
