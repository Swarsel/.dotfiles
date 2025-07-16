{ self, config, lib, minimal, ... }:
let
  primaryUser = config.swarselsystems.mainUser;
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
  };
in
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];



  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselprofiles = {
    toto = lib.mkIf (!minimal) true;
    minimal = lib.mkIf minimal true;
    btrfs = true;
  };
  swarselsystems = lib.recursiveUpdate
    {
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
    }
    sharedOptions;

  home-manager.users.${primaryUser} = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isLaptop = false;
        isNixos = true;
      }
      sharedOptions;
  };
}
