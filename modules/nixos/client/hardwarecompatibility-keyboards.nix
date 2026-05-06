{ pkgs, confLib, ... }:
{
  config = {
    users.persistentIds.plugdev = confLib.mkIds 953;

    services.udev.packages = with pkgs; [
      qmk-udev-rules
      vial
      via
    ];
  };
}
