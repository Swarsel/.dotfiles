{ lib, config, ... }:
{
  options.swarselprofiles.personal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselprofiles.personal {
    swarselmodules = {
      anki = lib.mkDefault true;
      anki-tray = lib.mkDefault true;
      atuin = lib.mkDefault true;
      autotiling = lib.mkDefault true;
      batsignal = lib.mkDefault true;
      blueman-applet = lib.mkDefault true;
      desktop = lib.mkDefault true;
      direnv = lib.mkDefault true;
      element-desktop = lib.mkDefault true;
      element-tray = lib.mkDefault true;
      emacs = lib.mkDefault true;
      env = lib.mkDefault true;
      eza = lib.mkDefault true;
      firefox = lib.mkDefault true;
      fuzzel = lib.mkDefault true;
      gammastep = lib.mkDefault true;
      general = lib.mkDefault true;
      git = lib.mkDefault true;
      gnome-keyring = lib.mkDefault true;
      gpgagent = lib.mkDefault true;
      hexchat = lib.mkDefault true;
      kanshi = lib.mkDefault true;
      kdeconnect = lib.mkDefault true;
      kitty = lib.mkDefault true;
      mail = lib.mkDefault true;
      mako = lib.mkDefault true;
      nix-index = lib.mkDefault true;
      nixgl = lib.mkDefault true;
      nix-your-shell = lib.mkDefault true;
      nm-applet = lib.mkDefault true;
      obs-studio = lib.mkDefault true;
      obsidian = lib.mkDefault true;
      obsidian-tray = lib.mkDefault true;
      opkssh = lib.mkDefault true;
      ownpackages = lib.mkDefault true;
      packages = lib.mkDefault true;
      passwordstore = lib.mkDefault true;
      programs = lib.mkDefault true;
      sops = lib.mkDefault false;
      spicetify = lib.mkDefault true;
      spotify-player = lib.mkDefault true;
      ssh = lib.mkDefault true;
      starship = lib.mkDefault true;
      stylix = lib.mkDefault true;
      sway = lib.mkDefault true;
      swayidle = lib.mkDefault true;
      swaylock = lib.mkDefault true;
      swayosd = lib.mkDefault true;
      symlink = lib.mkDefault true;
      tmux = lib.mkDefault true;
      vesktop = lib.mkDefault true;
      vesktop-tray = lib.mkDefault true;
      syncthing-tray = lib.mkDefault true;
      waybar = lib.mkDefault true;
      yubikey = lib.mkDefault false;
      yubikeytouch = lib.mkDefault true;
      zellij = lib.mkDefault true;
      zsh = lib.mkDefault true;
    };
  };

}
