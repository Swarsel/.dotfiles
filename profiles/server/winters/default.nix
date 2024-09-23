{ inputs, outputs, config, pkgs, lib, ... }:
{

  imports = [
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix

    ../../optional/nixos/autologin.nix
    ../../server/common

  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    inherit (outputs) overlays;
    config = {
      allowUnfree = true;
    };
  };


  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "winters";
    firewall.enable = true;
  };


  swarselsystems = {
    hasBluetooth = false;
    hasFingerprint = false;
    impermanence = false;
    isBtrfs = false;
    initialSetup = true;
    flakePath = "/home/swarsel/.dotfiles";
    server = {
      enable = true;
      kavita = false;
      navidrome = false;
      jellyfin = false;
      spotifyd = false;
      mpd = false;
      matrix = false;
    };
  };

}
