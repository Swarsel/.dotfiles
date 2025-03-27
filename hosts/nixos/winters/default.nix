{ self, inputs, primaryUser, ... }:
let
  modulesPath = "${self}/modules";
in
{

  imports = [
    ./hardware-configuration.nix

    "${modulesPath}/nixos/optional/autologin.nix"
    "${modulesPath}/nixos/server"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${modulesPath}/home/server"
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
    isImpermanence = false;
    isBtrfs = false;
    isLinux = true;
    server = {
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
