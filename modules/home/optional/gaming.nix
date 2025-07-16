{ lib, config, pkgs, ... }:
{
  options.swarselmodules.optional.gaming = lib.mkEnableOption "optional gaming settings";
  config = lib.mkIf config.swarselmodules.optional.gaming {
    # specialisation = {
    #   gaming.configuration = {
    home.packages = with pkgs; [
      lutris
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
    #   };
    # };
  };
}
