{ lib, config, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    tmp.cleanOnBoot = true;
  };

  networking = {
    nftables.enable = lib.mkForce false;
    hostName = "milkywell";
    enableIPv6 = true;
    domain = "subnet03112148.vcn03112148.oraclevcn.com";
  };

  hardware = {
    enableAllFirmware = lib.mkForce false;
  };

  swarselprofiles = {
    minimal = lib.mkIf minimal true;
    server.syncserver = true;
  };
  swarselsystems = lib.recursiveUpdate
    {
      info = "VM.Standard.E2.1.Micro";
      isImpermanence = true;
      isSecureBoot = false;
      isCrypted = true;
      isSwap = true;
      rootDisk = "/dev/sda";
      swapSize = "4G";
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    swarselsystems = lib.recursiveUpdate
      { }
      sharedOptions;
  };

}
