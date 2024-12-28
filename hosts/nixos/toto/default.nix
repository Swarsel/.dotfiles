{ self, inputs, outputs, config, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
  sharedOptions = {
    isBtrfs = true;
  };
in
{

  imports = [
    inputs.disko.nixosModules.disko
    "${self}/hosts/nixos/toto/disk-config.nix"
    ./hardware-configuration.nix

    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.lanzaboote.nixosModules.lanzaboote

    "${profilesPath}/optional/nixos/autologin.nix"
    "${profilesPath}/common/nixos/settings.nix"
    "${profilesPath}/common/nixos/home-manager.nix"
    "${profilesPath}/common/nixos/xserver.nix"
    "${profilesPath}/common/nixos/users.nix"
    "${profilesPath}/common/nixos/impermanence.nix"
    "${profilesPath}/common/nixos/lanzaboote.nix"
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
    sbctl
  ];

  system.stateVersion = lib.mkForce "23.05";

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };


  networking = {
    hostName = "toto";
    firewall.enable = false;
  };

  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      isImpermanence = true;
      isCrypted = true;
      isSecureBoot = true;
      isSwap = true;
      swapSize = "8G";
      rootDisk = "/dev/nvme0n1";
    }
    sharedOptions;

  home-manager.users.swarsel.swarselsystems = lib.recursiveUpdate
    {
      isLaptop = false;
      isNixos = true;
      flakePath = "/home/swarsel/.dotfiles";
    }
    sharedOptions;

}
