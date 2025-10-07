{ lib, config, ... }:
{
  options.swarselprofiles.personal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselprofiles.personal {
    swarselmodules = {
      packages = lib.mkDefault true;
      ownpackages = lib.mkDefault true;
      general = lib.mkDefault true;
      nixgl = lib.mkDefault true;
      sops = lib.mkDefault false;
      yubikey = lib.mkDefault false;
      ssh = lib.mkDefault true;
      stylix = lib.mkDefault true;
      desktop = lib.mkDefault true;
      symlink = lib.mkDefault true;
      env = lib.mkDefault true;
      programs = lib.mkDefault true;
      nix-index = lib.mkDefault true;
      passwordstore = lib.mkDefault true;
      direnv = lib.mkDefault true;
      eza = lib.mkDefault true;
      atuin = lib.mkDefault true;
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
      kdeconnect = lib.mkDefault true;
      mako = lib.mkDefault true;
      swayosd = lib.mkDefault true;
      yubikeytouch = lib.mkDefault true;
      sway = lib.mkDefault true;
      niri = lib.mkDefault true;
      kanshi = lib.mkDefault true;
      gpgagent = lib.mkDefault true;
      gammastep = lib.mkDefault true;
      spicetify = lib.mkDefault true;
      nm-applet = lib.mkDefault true;
      obsidian-tray = lib.mkDefault true;
      anki-tray = lib.mkDefault true;
      element-tray = lib.mkDefault true;
      vesktop-tray = lib.mkDefault true;
    };
  };

}
