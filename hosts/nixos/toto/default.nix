{ self, inputs, pkgs, lib, primaryUser, ... }:
let
  modulesPath = "${self}/modules";
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    profiles = {
      toto = true;
    };
  };
in
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix

    "${modulesPath}/nixos/common/sharedsetup.nix"
    "${modulesPath}/home/common/sharedsetup.nix"
    "${self}/profiles/nixos"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        inputs.sops-nix.homeManagerModules.sops
        "${modulesPath}/home/common/sharedsetup.nix"
        "${self}/profiles/home"
      ];
    }
  ];


  environment.systemPackages = with pkgs; [
    curl
    git
    gnupg
    rsync
    ssh-to-age
    sops
    vim
    just
    sbctl
  ];

  system.stateVersion = lib.mkForce "23.05";

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };


  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselsystems = lib.recursiveUpdate
    {
      info = "~SwarselSystems~ remote install helper";
      wallpaper = self + /wallpaper/lenovowp.png;
      isImpermanence = true;
      isCrypted = false;
      isSecureBoot = false;
      isSwap = false;
      swapSize = "8G";
      # rootDisk = "/dev/nvme0n1";
      rootDisk = "/dev/sda";
      # rootDisk = "/dev/vda";
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isLaptop = false;
        isNixos = true;
      }
      sharedOptions;
  };
}
