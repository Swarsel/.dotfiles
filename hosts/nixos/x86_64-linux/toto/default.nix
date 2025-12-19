{ self, lib, ... }:
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  topology.self.interfaces."bootstrapper" = { };

  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselprofiles = {
    minimal = lib.mkForce true;
  };

  swarselmodules = {
    server = {
      network = lib.mkForce false;
      diskEncryption = lib.mkForce false;
    };
  };

  swarselsystems = {
    info = "~SwarselSystems~ remote install helper";
    wallpaper = self + /files/wallpaper/lenovowp.png;
    isImpermanence = true;
    isCrypted = true;
    isSecureBoot = false;
    isSwap = true;
    swapSize = "2G";
    # rootDisk = "/dev/nvme0n1";
    rootDisk = "/dev/vda";
    # rootDisk = "/dev/vda";
    isBtrfs = true;
    isLinux = true;
    isLaptop = false;
    isNixos = true;
  };

}
