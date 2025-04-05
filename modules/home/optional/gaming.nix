{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.optional.gaming = lib.mkEnableOption "optional gaming settings";
  config = lib.mkIf config.swarselsystems.modules.optional.gaming {
    # specialisation = {
    #   gaming.configuration = {
    home.packages = with pkgs; [
      lutris
      wine
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
