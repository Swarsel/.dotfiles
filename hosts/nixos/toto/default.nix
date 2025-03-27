{ self, inputs, pkgs, lib, primaryUser, ... }:
let
  modulesPath = "${self}/modules";
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
  };
in
{

  imports = [
    "${self}/hosts/nixos/toto/disk-config.nix"
    ./hardware-configuration.nix

    "${modulesPath}/nixos/optional/autologin.nix"
    "${modulesPath}/nixos/common/settings.nix"
    "${modulesPath}/nixos/common/sharedsetup.nix"
    "${modulesPath}/nixos/common/home-manager.nix"
    "${modulesPath}/nixos/common/home-manager-extra.nix"
    "${modulesPath}/nixos/common/xserver.nix"
    "${modulesPath}/nixos/common/users.nix"
    "${modulesPath}/nixos/common/impermanence.nix"
    "${modulesPath}/nixos/common/lanzaboote.nix"
    "${modulesPath}/nixos/common/sops.nix"
    "${modulesPath}/nixos/server/ssh.nix"
    "${modulesPath}/home/common/sharedsetup.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        inputs.sops-nix.homeManagerModules.sops
        "${modulesPath}/home/common/settings.nix"
        "${modulesPath}/home/common/sops.nix"
        "${modulesPath}/home/common/ssh.nix"
        "${modulesPath}/home/common/sharedsetup.nix"
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
      wallpaper = self + /wallpaper/lenovowp.png;
      isImpermanence = true;
      isCrypted = true;
      isSecureBoot = false;
      isSwap = true;
      swapSize = "8G";
      # rootDisk = "/dev/nvme0n1";
      rootDisk = "/dev/vda";
    }
    sharedOptions;

  home-manager.users."${primaryUser}".swarselsystems = lib.recursiveUpdate
    {
      isLaptop = false;
      isNixos = true;
    }
    sharedOptions;

}
