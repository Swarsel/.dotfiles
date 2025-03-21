{ self, config, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    {
      _module.args.diskDevice = config.swarselsystems.rootDisk;
    }
    "${profilesPath}/nixos/optional/autologin.nix"
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


  swarselsystems = {
    wallpaper = self + /wallpaper/lenovowp.png;
    initialSetup = true;
    isPublic = true;
    isLinux = true;
    isImpermanence = true;
    isCrypted = true;
    isSecureBoot = false;
    isSwap = true;
    swapSize = "4G";
    rootDisk = "/dev/vda";
  };

  home-manager.users.swarsel.swarselsystems = {
    isNixos = true;
    isPublic = true;
    flakePath = "/home/swarsel/.dotfiles";
  };
}
