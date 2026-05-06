{ self, ... }:
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    "${self}/profiles/nixos/minimal"
  ];

  topology.self.interfaces."bootstrapper" = { };

  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselsystems = {
    info = "~SwarselSystems~ remote install helper";
    wallpaper = self + /files/wallpaper/landscape/lenovowp.png;
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
