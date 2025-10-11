{ lib, config, pkgs, nixosConfig ? config, ... }:
let
  inherit (config.swarselsystems) isNixos;
in
{
  options.swarselmodules.optional.gaming = lib.mkEnableOption "optional gaming settings";
  config = lib.mkIf config.swarselmodules.optional.gaming {
    # specialisation = {
    #   gaming.configuration = {
    home.packages = with pkgs; [
      # lutris
      wine
      protonplus
      winetricks
      libudev-zero
      dwarfs
      fuse-overlayfs
      # steam
      steam-run
      patchelf
      gamescope
      vulkan-tools
      moonlight-qt
      ns-usbloader

      quark-goldleaf

      # gog games installing
      heroic

      # minecraft
      prismlauncher # has overrides
      temurin-bin-17

      pokefinder
      retroarch
      flips
    ];

    programs.lutris = {
      enable = true;
      extraPackages = with pkgs; [
        winetricks
        gamescope
        umu-launcher
      ];
      steamPackage = if isNixos then nixosConfig.programs.steam.package else pkgs.steam;
      winePackages = with pkgs; [
        wineWow64Packages.waylandFull
      ];
      protonPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    #   };
    # };
  };
}
