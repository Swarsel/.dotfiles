{ lib, pkgs, config, ... }:
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
    ./gpg-agent.nix
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  programs = {
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "swarsel";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
    keyboard.layout = "us"; # TEMPLATE
    sessionVariables = {
      FLAKE = "$HOME/.dotfiles";
    };
  };

}
