{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${m}/home/common/anki.nix"
    "${m}/home/common/tray-applets.nix"
    "${m}/home/common/blueman-applet.nix"
    "${m}/home/common/custom-packages.nix"
    "${m}/home/common/desktop.nix"
    "${m}/home/common/direnv.nix"
    "${m}/home/common/element.nix"
    "${m}/home/common/eza.nix"
    "${m}/home/common/firefox.nix"
    "${m}/home/common/fuzzel.nix"
    "${m}/home/common/settings.nix"
    "${m}/home/common/gnome-keyring.nix"
    "${m}/home/common/gpg-agent.nix"
    "${m}/home/common/kitty.nix"
    "${m}/home/common/nix-index.nix"
    "${m}/home/common/nix-your-shell.nix"
    "${m}/home/common/network-manager-applet.nix"
    "${m}/home/common/packages.nix"
    "${m}/home/common/password-store.nix"
    "${m}/home/common/programs.nix"
    "${m}/home/common/spicetify.nix"
    "${m}/home/common/starship.nix"
    "${m}/home/common/stylix.nix"
    "${m}/home/common/swayidle.nix"
    "${m}/home/common/symlink.nix"
    "${m}/home/common/yubikey-touch-detector.nix"
    "${m}/home/common/zellij.nix"
    "${m}/home/common/zellij-keybinds.nix"
    "${m}/home/common/zsh.nix"
  ];

  swarselsystems.trayApplets.obsidian.enable = false;
}
