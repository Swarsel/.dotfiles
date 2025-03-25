{ pkgs, ... }:
{
  services.udev.packages = with pkgs; [
    qmk-udev-rules
    vial
    via
  ];
}
