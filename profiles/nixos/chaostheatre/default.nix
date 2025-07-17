{ lib, config, ... }:
{
  options.swarselprofiles.chaostheatre = lib.mkEnableOption "is this a chaostheatre host";
  config = lib.mkIf config.swarselprofiles.chaostheatre {
    swarselmodules = {
      packages = lib.mkDefault true;
      general = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      users = lib.mkDefault true;
      sops = lib.mkDefault true;
      env = lib.mkDefault true;
      security = lib.mkDefault true;
      systemdTimeout = lib.mkDefault true;
      hardware = lib.mkDefault true;
      pulseaudio = lib.mkDefault true;
      pipewire = lib.mkDefault true;
      network = lib.mkDefault true;
      time = lib.mkDefault true;
      stylix = lib.mkDefault true;
      programs = lib.mkDefault true;
      zsh = lib.mkDefault true;
      syncthing = lib.mkDefault true;
      blueman = lib.mkDefault true;
      networkDevices = lib.mkDefault true;
      gvfs = lib.mkDefault true;
      interceptionTools = lib.mkDefault true;
      swayosd = lib.mkDefault true;
      ppd = lib.mkDefault true;
      yubikey = lib.mkDefault false;
      ledger = lib.mkDefault true;
      keyboards = lib.mkDefault true;
      login = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      nvd = lib.mkDefault true;
      gnome-keyring = lib.mkDefault true;
      sway = lib.mkDefault true;
      xdg-portal = lib.mkDefault true;
      distrobox = lib.mkDefault true;
      appimage = lib.mkDefault true;
      lid = lib.mkDefault true;
      lowBattery = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      autologin = lib.mkDefault true;
    };

  };

}
