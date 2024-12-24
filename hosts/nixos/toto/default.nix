{ self, inputs, outputs, config, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
in
{

  imports = [
    inputs.disko.nixosModules.disko
    "${self}/hosts/nixos/toto/disk-config.nix"
    {
      _module.args = {
        withSwap = true;
        swapSize = "8";
        rootDisk = "/dev/vda";
        withImpermanence = true;
        withEncryption = true;
      };
    }
    ./hardware-configuration.nix

    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence

    "${profilesPath}/optional/nixos/autologin.nix"
    "${profilesPath}/common/nixos/settings.nix"
    "${profilesPath}/common/nixos/home-manager.nix"
    "${profilesPath}/common/nixos/xserver.nix"
    "${profilesPath}/common/nixos/users.nix"
    "${profilesPath}/common/nixos/impermanence.nix"
    "${profilesPath}/common/nixos/sops.nix"
    "${profilesPath}/server/nixos/ssh.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        inputs.sops-nix.homeManagerModules.sops
        "${profilesPath}/common/home/settings.nix"
        "${profilesPath}/common/home/sops.nix"
        "${profilesPath}/common/home/ssh.nix"

      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    gnupg
    rsync
    ssh-to-age
    sops
    vim
    just
  ];

  system.stateVersion = lib.mkForce "23.05";

  boot = {
    loader.systemd-boot.enable = lib.mkForce true;
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };


  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselsystems = {
    wallpaper = self + /wallpaper/lenovowp.png;
    impermanence = true;
    isBtrfs = true;
    isCrypted = true;
    initialSetup = true;
  };

  home-manager.users.swarsel.swarselsystems = {
    isLaptop = false;
    isNixos = true;
    isBtrfs = true;
    flakePath = "/home/swarsel/.dotfiles";
  };

}
