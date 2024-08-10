{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lutris
    wine
    libudev-zero
    dwarfs
    fuse-overlayfs
    # steam
    # steam-run
    patchelf
    gamescope
    vulkan-tools
    moonlight-qt
    ns-usbloader

    # gog games installing
    heroic

    # minecraft
    prismlauncher # has overrides
    temurin-bin-17
  ];
}
