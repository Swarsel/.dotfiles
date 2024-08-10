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
  config.swarselsystems.waybarModules = lib.mkIf config.swarselsystems.isLaptop [
    "custom/outer-left-arrow-dark"
    "mpris"
    "custom/left-arrow-light"
    "network"
    "custom/vpn"
    "custom/left-arrow-dark"
    "pulseaudio"
    "custom/left-arrow-light"
    "battery"
    "custom/left-arrow-dark"
    "group/hardware"
    "custom/left-arrow-light"
    "clock#2"
    "custom/left-arrow-dark"
    "clock#1"
  ];
}
