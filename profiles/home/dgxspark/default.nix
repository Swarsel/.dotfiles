{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${m}/home/common/atuin.nix"
    "${m}/home/common/bash.nix"
    "${m}/home/common/blueman-applet.nix"
    "${m}/home/common/direnv.nix"
    "${m}/home/common/eza.nix"
    "${m}/home/common/firefox.nix"
    "${m}/home/common/fuzzel.nix"
    "${m}/home/common/settings.nix"
    "${m}/home/common/git.nix"
    "${m}/home/common/gpg-agent.nix"
    "${m}/home/common/kitty.nix"
    "${m}/home/common/nix-index.nix"
    "${m}/home/common/nixgl.nix"
    "${m}/home/common/nix-your-shell.nix"
    "${m}/home/common/network-manager-applet.nix"
    "${m}/home/common/sops.nix"
    "${m}/home/common/starship.nix"
    "${m}/home/common/stylix.nix"
    "${m}/home/common/tmux.nix"
    "${m}/home/common/zellij.nix"
    "${m}/home/common/zellij-keybinds.nix"
    "${m}/home/common/zsh.nix"
  ];
}
