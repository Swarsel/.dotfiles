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
    enableIPv6 = false;
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
      kavita = true;
      navidrome = true;
      jellyfin = true;
      spotifyd = true;
      mpd = false;
      matrix = true;
      nextcloud = true;
      immich = true;
      paperless = true;
      transmission = true;
      syncthing = true;
      monitoring = true;
    };
  };

}
