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
    server = {
      enable = true;
      kavita = true;
      navidrome = true;
      jellyfin = true;
      spotifyd = true;
      mpd = true;
      matrix = true;
    };
    shellAliases = {
      nswitch = "cd /.dotfiles; sudo nixos-rebuild --flake .#$(hostname) switch; cd -;";
    };
  };

}
