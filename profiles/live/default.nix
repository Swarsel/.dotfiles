{ inputs, outputs, config, pkgs, lib, ... }:
{

  imports = [

    # ../optional/nixos/steam.nix
    # ../optional/nixos/virtualbox.nix
    # ../optional/nixos/vmware.nix
    ../optional/nixos/autologin.nix
    ../optional/nixos/nswitch-rcm.nix
    # ../optional/nixos/work.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        ../optional/home/gaming.nix
        # ../optional/home/work.nix
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    inherit (outputs) overlays;
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  networking.networkmanager.wifi.scanRandMacAddress = false;

  boot = {
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  system.stateVersion = lib.mkForce "23.05";
  services.getty.autologinUser = lib.mkForce "swarsel";

  networking = {
    hostName = "live";
    wireless.enable = lib.mkForce false;
    firewall.enable = true;
  };


  swarselsystems = {
    wallpaper = ../../wallpaper/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    impermanence = false;
    initialSetup = true;
    isBtrfs = false;
  };

  home-manager.users.swarsel.swarselsystems = {
    isLaptop = false;
    isNixos = true;
    isBtrfs = false;
    startup = [
      { command = "nextcloud --background"; }
      { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
      { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
      { command = "ANKI_WAYLAND=1 anki"; }
      { command = "OBSIDIAN_USE_WAYLAND=1 obsidian"; }
      { command = "nm-applet"; }
      { command = "teams-for-linux"; }
      { command = "1password"; }
      { command = "feishin"; }
    ];
  };
}
