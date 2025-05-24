{ self, inputs, config, pkgs, lib, primaryUser, ... }:
let
  sharedOptions = {
    isBtrfs = false;
    isLinux = true;
    isPublic = true;
    profiles = {
      chaostheatre = true;
    };
  };
in
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    {
      _module.args.diskDevice = config.swarselsystems.rootDisk;
    }
    "${self}/hosts/nixos/chaostheatre/options.nix"
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${self}/modules/home/common/settings.nix"
        "${self}/hosts/nixos/chaostheatre/options-home.nix"
        "${self}/modules/home/common/sharedsetup.nix"
      ];
    }
  ];

  environment.variables = {
    WLR_RENDERER_ALLOW_SOFTWARE = 1;
  };

  services.qemuGuest.enable = true;

  boot = {
    loader.systemd-boot.enable = lib.mkForce true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "chaostheatre";
    firewall.enable = true;
  };


  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      initialSetup = true;
      isImpermanence = true;
      isCrypted = true;
      isSecureBoot = false;
      isSwap = true;
      swapSize = "4G";
      rootDisk = "/dev/vda";
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isNixos = true;
      }
      sharedOptions;
  };
}
