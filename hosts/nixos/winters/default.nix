{ lib, config, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
  sharedOptions = {
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
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
    inherit (config.repo.secrets.local) hostId;
    hostName = "winters";
    firewall.enable = true;
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
  };


  swarselprofiles = {
    server.local = true;
  };
  swarselsystems = lib.recursiveUpdate
    {
      info = "ASRock J4105-ITX, 32GB RAM";
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
