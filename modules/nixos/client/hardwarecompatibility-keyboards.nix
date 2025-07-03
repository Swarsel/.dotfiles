{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.keyboards = lib.mkEnableOption "keyboards config";
  config = lib.mkIf config.swarselsystems.modules.keyboards {
    services.udev.packages = with pkgs; [
      qmk-udev-rules
      vial
      via
    ];
  };
}
