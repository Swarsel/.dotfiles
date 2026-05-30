{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${self}/profiles/home/public-small"
    "${m}/home/common/attic-store-push.nix"
    "${m}/home/common/atuin.nix"
    "${m}/home/common/hexchat.nix"
    "${m}/home/common/kdeconnect.nix"
    "${m}/home/common/khal.nix"
    "${m}/home/common/nixgl.nix"
    "${m}/home/common/obs-studio.nix"
    "${m}/home/common/opkssh.nix"
    "${m}/home/common/spotify-player.nix"
    "${m}/home/common/swayosd.nix"
    "${m}/home/common/tmux.nix"
    "${m}/home/common/vesktop.nix"
    "${m}/home/common/shikane.nix"
    "${m}/home/common/syncthing-tray.nix"
    "${m}/home/common/waybar.nix"
  ];

  swarselsystems.trayApplets.obsidian.enable = false;
}
