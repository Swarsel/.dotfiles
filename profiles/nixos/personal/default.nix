{ lib, config, ... }:
{
  options.swarselprofiles.personal = lib.mkEnableOption "is this a personal host";
  config = lib.mkIf config.swarselprofiles.personal {
    swarselmodules = {
      # keyd = lib.mkDefault true;
      appimage = lib.mkDefault true;
      autologin = lib.mkDefault true;
      blueman = lib.mkDefault true;
      boot = lib.mkDefault true;
      btrfs = lib.mkDefault true;
      distrobox = lib.mkDefault true;
      env = lib.mkDefault true;
      general = lib.mkDefault true;
      gnome-keyring = lib.mkDefault true;
      gvfs = lib.mkDefault true;
      hardware = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      interceptionTools = lib.mkDefault true;
      keyboards = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      ledger = lib.mkDefault true;
      lid = lib.mkDefault true;
      login = lib.mkDefault true;
      lowBattery = lib.mkDefault false;
      network = lib.mkDefault true;
      networkDevices = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      nvd = lib.mkDefault true;
      packages = lib.mkDefault true;
      pii = lib.mkDefault true;
      pipewire = lib.mkDefault true;
      ppd = lib.mkDefault true;
      programs = lib.mkDefault true;
      pulseaudio = lib.mkDefault true;
      remotebuild = lib.mkDefault true;
      security = lib.mkDefault true;
      sops = lib.mkDefault true;
      stylix = lib.mkDefault true;
      sway = lib.mkDefault true;
      swayosd = lib.mkDefault true;
      syncthing = lib.mkDefault true;
      systemdTimeout = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      uwsm = lib.mkDefault true;
      xdg-portal = lib.mkDefault true;
      xserver = lib.mkDefault true;
      yubikey = lib.mkDefault true;
      zsh = lib.mkDefault true;

    };
    home-manager.users."${config.swarselsystems.mainUser}" = {
      swarselprofiles = {
        personal = lib.mkDefault true;
      };
    };

  };

}
