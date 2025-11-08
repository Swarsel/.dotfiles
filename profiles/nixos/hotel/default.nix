{ lib, config, ... }:
{
  options.swarselprofiles.hotel = lib.mkEnableOption "is this a hotel host";
  config = lib.mkIf config.swarselprofiles.hotel {
    swarselmodules = {
      packages = lib.mkForce true;
      general = lib.mkForce true;
      home-manager = lib.mkForce true;
      xserver = lib.mkForce true;
      users = lib.mkForce true;
      sops = lib.mkForce true;
      env = lib.mkForce true;
      security = lib.mkForce true;
      systemdTimeout = lib.mkForce true;
      hardware = lib.mkForce true;
      pulseaudio = lib.mkForce true;
      pipewire = lib.mkForce true;
      network = lib.mkForce true;
      time = lib.mkForce true;
      stylix = lib.mkForce true;
      programs = lib.mkForce true;
      zsh = lib.mkForce true;
      syncthing = lib.mkForce true;
      blueman = lib.mkForce true;
      networkDevices = lib.mkForce true;
      gvfs = lib.mkForce true;
      interceptionTools = lib.mkForce true;
      swayosd = lib.mkForce true;
      ppd = lib.mkForce true;
      yubikey = lib.mkForce false;
      ledger = lib.mkForce true;
      keyboards = lib.mkForce true;
      login = lib.mkForce true;
      nix-ld = lib.mkForce true;
      impermanence = lib.mkForce true;
      nvd = lib.mkForce true;
      gnome-keyring = lib.mkForce true;
      sway = lib.mkForce true;
      xdg-portal = lib.mkForce true;
      distrobox = lib.mkForce true;
      appimage = lib.mkForce true;
      lid = lib.mkForce true;
      lowBattery = lib.mkForce true;
      lanzaboote = lib.mkForce true;
      autologin = lib.mkForce true;
    };

  };

}
