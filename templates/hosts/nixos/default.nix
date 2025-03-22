{ self, inputs, pkgs, lib, primaryUser, ... }:
let
  profilesPath = "${self}/profiles";
  sharedOptions = {
    isBtrfs = true;
  };
in
{

  imports = [
    # ---- nixos-hardware here ----

    ./hardware-configuration.nix
    ./disk-config.nix

    "${profilesPath}/nixos/optional/virtualbox.nix"
    # "${profilesPath}/nixos/optional/vmware.nix"
    "${profilesPath}/nixos/optional/autologin.nix"
    "${profilesPath}/nixos/optional/nswitch-rcm.nix"
    "${profilesPath}/nixos/optional/gaming.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${profilesPath}/home/optional/gaming.nix"
      ];
    }
  ];

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

  home-manager.users."${primaryUser}".swarselsystems = lib.recursiveUpdate
    {
      isLaptop = true;
      isNixos = true;
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
