{ config, ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  globals.hosts.${config.node.name}.ipv4 = config.repo.secrets.local.ipv4;

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

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    isImpermanence = false;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
  };

}
