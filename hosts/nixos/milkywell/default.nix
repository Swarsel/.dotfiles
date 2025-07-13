{ lib, config, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
  };
  profiles = {
    minimal = lib.mkIf minimal true;
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

  swarselsystems = lib.recursiveUpdate
    {
      info = "VM.Standard.E2.1.Micro";
      isImpermanence = true;
      isSecureBoot = false;
      isCrypted = true;
      isSwap = true;
      rootDisk = "/dev/sda";
      swapSize = "4G";
      profiles = {
        server.syncserver = true;
      };
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    swarselsystems = lib.recursiveUpdate
      { }
      sharedOptions;
  };

}
