{ self, inputs, outputs, pkgs, lib, ... }:
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

    "${profilesPath}/nixos/optional/autologin.nix"
    "${profilesPath}/nixos/common/settings.nix"
    "${profilesPath}/nixos/common/home-manager.nix"
    "${profilesPath}/nixos/common/xserver.nix"
    "${profilesPath}/nixos/common/users.nix"
    "${profilesPath}/nixos/common/impermanence.nix"
    "${profilesPath}/nixos/common/lanzaboote.nix"
    "${profilesPath}/nixos/common/sops.nix"
    "${profilesPath}/nixos/server/ssh.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = [
        inputs.sops-nix.homeManagerModules.sops
        "${profilesPath}/home/common/settings.nix"
        "${profilesPath}/home/common/sops.nix"
        "${profilesPath}/home/common/ssh.nix"

      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


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
      isSecureBoot = false;
      isSwap = true;
      isLinux = true;
      swapSize = "8G";
      # rootDisk = "/dev/nvme0n1";
      rootDisk = "/dev/vda";
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
