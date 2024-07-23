{ ... }:
{
  imports = [
    ./packages.nix
    ./sops.nix
    ./ssh.nix
    ./stylix.nix
    ./desktop.nix
    ./symlink.nix
    ./env.nix
    ./programs.nix
    ./nix-index.nix
    ./password-store.nix
    ./direnv.nix
    ./eza.nix
    ./git.nix
    ./fuzzel.nix
    ./starship.nix
    ./kitty.nix
    ./zsh.nix
    ./mail.nix
    ./emacs.nix
    ./waybar.nix
    ./firefox.nix
    ./gnome-keyring.nix
    ./kdeconnect.nix
    ./mako.nix
    ./sway.nix
  ];

}
