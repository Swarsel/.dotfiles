{ lib, config, ... }:
{
  options.swarselprofiles.dgxspark = lib.mkEnableOption "is this a dgx spark host";
  config = lib.mkIf config.swarselprofiles.dgxspark {
    swarselmodules = {
      anki = lib.mkDefault false;
      anki-tray = lib.mkDefault false;
      atuin = lib.mkDefault true;
      autotiling = lib.mkDefault false;
      batsignal = lib.mkDefault false;
      blueman-applet = lib.mkDefault true;
      desktop = lib.mkDefault false;
      direnv = lib.mkDefault true;
      element-desktop = lib.mkDefault false;
      element-tray = lib.mkDefault false;
      emacs = lib.mkDefault false;
      env = lib.mkDefault false;
      eza = lib.mkDefault true;
      firefox = lib.mkDefault true;
      fuzzel = lib.mkDefault true;
      gammastep = lib.mkDefault false;
      general = lib.mkDefault true;
      git = lib.mkDefault true;
      gnome-keyring = lib.mkDefault false;
      gpgagent = lib.mkDefault true;
      hexchat = lib.mkDefault false;
      kanshi = lib.mkDefault false;
      kdeconnect = lib.mkDefault false;
      kitty = lib.mkDefault true;
      mail = lib.mkDefault false;
      mako = lib.mkDefault false;
      niri = lib.mkDefault false;
      nix-index = lib.mkDefault true;
      nixgl = lib.mkDefault true;
      nix-your-shell = lib.mkDefault true;
      nm-applet = lib.mkDefault true;
      obs-studio = lib.mkDefault false;
      obsidian = lib.mkDefault false;
      obsidian-tray = lib.mkDefault false;
      ownpackages = lib.mkDefault false;
      packages = lib.mkDefault false;
      passwordstore = lib.mkDefault false;
      programs = lib.mkDefault false;
      sops = lib.mkDefault true;
      spicetify = lib.mkDefault false;
      spotify-player = lib.mkDefault false;
      ssh = lib.mkDefault false;
      starship = lib.mkDefault true;
      stylix = lib.mkDefault true;
      sway = lib.mkDefault false;
      swayidle = lib.mkDefault false;
      swaylock = lib.mkDefault false;
      swayosd = lib.mkDefault false;
      symlink = lib.mkDefault false;
      tmux = lib.mkDefault true;
      vesktop = lib.mkDefault false;
      vesktop-tray = lib.mkDefault false;
      syncthing-tray = lib.mkDefault false;
      waybar = lib.mkDefault false;
      yubikey = lib.mkDefault false;
      yubikeytouch = lib.mkDefault false;
      zellij = lib.mkDefault true;
      zsh = lib.mkDefault true;
    };
  };

}
