{ lib, config, ... }:
{
  options.swarselsystems.profiles.personal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselsystems.profiles.personal {
    swarselsystems.modules = {
      packages = lib.mkDefault true;
      ownpackages = lib.mkDefault true;
      general = lib.mkDefault true;
      nixgl = lib.mkDefault true;
      sops = lib.mkDefault true;
      yubikey = lib.mkDefault true;
      ssh = lib.mkDefault true;
      stylix = lib.mkDefault true;
      desktop = lib.mkDefault true;
      symlink = lib.mkDefault true;
      env = lib.mkDefault true;
      programs = lib.mkDefault true;
      nix-index = lib.mkDefault true;
      direnv = lib.mkDefault true;
      eza = lib.mkDefault true;
      git = lib.mkDefault true;
      fuzzel = lib.mkDefault true;
      starship = lib.mkDefault true;
      kitty = lib.mkDefault true;
      zsh = lib.mkDefault true;
      zellij = lib.mkDefault true;
      tmux = lib.mkDefault true;
      mail = lib.mkDefault true;
      emacs = lib.mkDefault true;
      waybar = lib.mkDefault true;
      firefox = lib.mkDefault true;
      gnome-keyring = lib.mkDefault true;
    };
  };

}
