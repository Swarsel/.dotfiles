{ self, inputs, outputs, config, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
  sharedOptions = {
    isBtrfs = true;
  };
in
{

  imports = outputs.nixModules ++ [
    # ---- nixos-hardware here ----

    ./hardware-configuration.nix
    ./disk-config.nix

    "${profilesPath}/optional/nixos/virtualbox.nix"
    # "${profilesPath}/optional/nixos/vmware.nix"
    "${profilesPath}/optional/nixos/autologin.nix"
    "${profilesPath}/optional/nixos/nswitch-rcm.nix"
    "${profilesPath}/optional/nixos/gaming.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        "${profilesPath}/optional/home/gaming.nix"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "TEMPLATE";
    firewall.enable = true;
  };

  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = true;
      isSecureBoot = true;
      isCrypted = true;
      isSwap = true;
      swapSize = "32G";
      rootDisk = "TEMPLATE";
    }
    sharedOptions;

  home-manager.users.swarsel.swarselsystems = lib.recursiveUpdate
    {
      isLaptop = true;
      isNixos = true;
      flakePath = "/home/swarsel/.dotfiles";
      cpuCount = 16;
      startup = [
        { command = "nextcloud --background"; }
        { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
        { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
        { command = "ANKI_WAYLAND=1 anki"; }
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian"; }
        { command = "nm-applet"; }
        { command = "feishin"; }
      ];
    }
    sharedOptions;
}
