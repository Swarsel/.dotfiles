{ lib, config, ... }:
{
  options.swarselprofiles.hotel = lib.mkEnableOption "is this a hotel host";
  config = lib.mkIf config.swarselprofiles.hotel {
    swarselmodules = {
      packages = lib.mkForce true;
      ownpackages = lib.mkForce true;
      general = lib.mkForce true;
      nixgl = lib.mkForce true;
      sops = lib.mkForce true;
      yubikey = lib.mkForce false;
      ssh = lib.mkForce true;
      stylix = lib.mkForce true;
      desktop = lib.mkForce true;
      symlink = lib.mkForce true;
      env = lib.mkForce false;
      programs = lib.mkForce true;
      nix-index = lib.mkForce true;
      direnv = lib.mkForce true;
      eza = lib.mkForce true;
      git = lib.mkForce false;
      fuzzel = lib.mkForce true;
      starship = lib.mkForce true;
      kitty = lib.mkForce true;
      zsh = lib.mkForce true;
      zellij = lib.mkForce true;
      tmux = lib.mkForce true;
      mail = lib.mkForce false;
      emacs = lib.mkForce true;
      waybar = lib.mkForce true;
      firefox = lib.mkForce true;
      gnome-keyring = lib.mkForce true;
      kdeconnect = lib.mkForce true;
      mako = lib.mkForce true;
      swayosd = lib.mkForce true;
      yubikeytouch = lib.mkForce true;
      sway = lib.mkForce true;
      kanshi = lib.mkForce true;
      gpgagent = lib.mkForce true;
      gammastep = lib.mkForce false;
    };
  };

}
