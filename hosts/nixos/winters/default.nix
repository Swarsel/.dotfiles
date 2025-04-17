{ lib, primaryUser, ... }:
let
  sharedOptions = {
    isBtrfs = false;
    isLinux = true;
    profiles = {
      server.local = true;
    };
  };
in
{

  imports = [
    ./hardware-configuration.nix
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


  swarselsystems = lib.recursiveUpdate
    {
      isImpermanence = false;
      isSecureBoot = true;
      isCrypted = true;
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      { }
      sharedOptions;
  };
}
