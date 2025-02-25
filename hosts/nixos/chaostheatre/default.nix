{ self, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    ./hardware-configuration.nix
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
  };

  home-manager.users.swarsel.swarselsystems = {
    isNixos = true;
    isPublic = true;
    flakePath = "/home/swarsel/.dotfiles";
  };
}
