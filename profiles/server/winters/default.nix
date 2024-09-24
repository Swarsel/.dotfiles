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
  };

  networking = {
    hostName = "winters";
    hostId = "b7778a4a";
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };


  swarselsystems = {
    hasBluetooth = false;
    hasFingerprint = false;
    impermanence = false;
    isBtrfs = false;
    flakePath = "/home/swarsel/.dotfiles";
    server = {
      enable = true;
      kavita = false;
      navidrome = true;
      jellyfin = false;
      spotifyd = false;
      mpd = false;
      matrix = false;
    };
  };

}
