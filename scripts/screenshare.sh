SHARESCREEN="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$(hostname)".config.home-manager.users."$(whoami)".swarselsystems.sharescreen)"

if [[ "$1" == "start" ]]; then
    wl-mirror "$SHARESCREEN" & sleep 0.1
    swaymsg output eDP-2 mode 1280x800
    swaymsg '[app_id=at.yrlf.wl_mirror] move to workspace 12:S'
    swaymsg '[app_id=at.yrlf.wl_mirror] fullscreen'
else
    swaymsg output eDP-2 mode 2560x1600
fi
