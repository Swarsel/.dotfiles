SHARESCREEN="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$(hostname)".config.home-manager.users."$(whoami)".swarselsystems.sharescreen)"

wl-mirror "$SHARESCREEN" & sleep 0.1
swaymsg '[app_id=at.yrlf.wl_mirror] move to workspace 12:S'
swaymsg '[app_id=at.yrlf.wl_mirror] fullscreen'