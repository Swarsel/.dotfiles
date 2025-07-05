{ self, config, pkgs, lib, minimal, ... }:
let
  mainUser = "demo";
  sharedOptions = {
    inherit mainUser;
    isBtrfs = false;
    isLinux = true;
    isPublic = true;
    profiles = {
      chaostheatre = lib.mkIf (!minimal) true;
      minimal = lib.mkIf minimal true;
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
      info = "~SwarselSystems~ demo host";
      wallpaper = self + /files/wallpaper/lenovowp.png;
      isImpermanence = true;
      isCrypted = true;
      isSecureBoot = false;
      isSwap = true;
      swapSize = "4G";
      rootDisk = "/dev/vda";
      profiles.btrfs = true;
    }
    sharedOptions;

  home-manager.users.${mainUser} = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isNixos = true;
      }
      sharedOptions;
  };
}
