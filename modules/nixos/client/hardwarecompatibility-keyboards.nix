{ lib, config, pkgs, ... }:
{
  options.swarselmodules.keyboards = lib.mkEnableOption "keyboards config";
  config = lib.mkIf config.swarselmodules.keyboards {
    services.udev.packages = with pkgs; [
      qmk-udev-rules
      vial
      via
    ];
  };
}
