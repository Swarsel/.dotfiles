{ self, inputs, outputs, config, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = outputs.nixModules ++ [

    ./hardware-configuration.nix

    "${profilesPath}/optional/nixos/autologin.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  environment.variables = {
    WLR_ALLOW_SOFTWARE_RENDERER = 1;
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
  };

  home-manager.users.swarsel.swarselsystems = {
    isNixos = true;
    isPublic = true;
    flakePath = "/home/swarsel/.dotfiles";
  };
}
