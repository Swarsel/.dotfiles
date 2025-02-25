{ self, inputs, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    ./hardware-configuration.nix

    "${profilesPath}/nixos/optional/autologin.nix"
    "${profilesPath}/nixos/server"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        "${profilesPath}/home/server"
      ];
    }
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "winters";
    hostId = "b7778a4a";
    firewall.enable = true;
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  swarselsystems = {
    hasBluetooth = false;
    hasFingerprint = false;
    isImpermanence = false;
    isBtrfs = false;
    isLinux = true;
    flakePath = "/home/swarsel/.dotfiles";
    server = {
      enable = true;
      kavita = true;
      navidrome = true;
      jellyfin = true;
      spotifyd = true;
      mpd = false;
      matrix = true;
      nextcloud = true;
      immich = true;
      paperless = true;
      transmission = true;
      syncthing = true;
      monitoring = true;
      freshrss = true;
    };
  };

}
