{ self, inputs, pkgs, lib, primaryUser, ... }:
let
  modulesPath = "${self}/modules";
  sharedOptions = {
    isBtrfs = true;
  };
in
{

  imports = [
    # ---- nixos-hardware here ----

    ./hardware-configuration.nix
    ./disk-config.nix

    "${modulesPath}/nixos/optional/virtualbox.nix"
    # "${modulesPath}/nixos/optional/vmware.nix"
    "${modulesPath}/nixos/optional/autologin.nix"
    "${modulesPath}/nixos/optional/nswitch-rcm.nix"
    "${modulesPath}/nixos/optional/gaming.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${modulesPath}/home/optional/gaming.nix"
      ];
    }
  ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "TEMPLATE";
    firewall.enable = true;
  };

  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = true;
      isSecureBoot = true;
      isCrypted = true;
      isSwap = true;
      swapSize = "32G";
      rootDisk = "TEMPLATE";
    }
    sharedOptions;

  home-manager.users."${primaryUser}".swarselsystems = lib.recursiveUpdate
    {
      isLaptop = true;
      isNixos = true;
      cpuCount = 16;
    }
    sharedOptions;
}
