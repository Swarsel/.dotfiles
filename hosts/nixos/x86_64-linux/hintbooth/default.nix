{ lib, minimal, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  swarselsystems = {
    info = "HUNSN RM02, 8GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
    rootDisk = "/dev/sda";
    swapSize = "8G";
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
    router = false;
  };

}
