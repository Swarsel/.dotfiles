{ self, lib, minimal, ... }:
let
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    profiles = {
      toto = lib.mkIf (!minimal) true;
      minimal = lib.mkIf minimal true;
      btrfs = lib.mkIf minimal true;
    };
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
      rootDisk = "/dev/sda";
      # rootDisk = "/dev/vda";
    }
    sharedOptions;

  home-manager.users."setup" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isLaptop = false;
        isNixos = true;
      }
      sharedOptions;
  };
}
