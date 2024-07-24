{ lib, config, ... }:
{
  options.swarselsystems.isLaptop = lib.mkEnableOption "laptop host";
  config.swarselsystems.touchpad = lib.mkIf config.swarselsystems.isLaptop {
    "type:touchpad" = {
      dwt = "enabled";
      tap = "enabled";
      natural_scroll = "enabled";
      middle_emulation = "enabled";
    };
  };
}
