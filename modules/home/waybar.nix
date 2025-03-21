{ lib, config, ... }:
let
  generateIcons = n: lib.concatStringsSep " " (builtins.map (x: "{icon" + toString x + "}") (lib.range 0 (n - 1)));
in
{
  options.swarselsystems = {
    cpuString = lib.mkOption {
      type = lib.types.str;
      default = generateIcons config.swarselsystems.cpuCount;
      description = "The generated icons string for use by Waybar.";
      internal = true;
    };
    waybarModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "custom/outer-left-arrow-dark"
        "mpris"
        "custom/left-arrow-light"
        "network"
        "custom/vpn"
        "custom/left-arrow-dark"
        "pulseaudio"
        "custom/left-arrow-light"
        "custom/pseudobat"
        "battery"
        "custom/left-arrow-dark"
        "group/hardware"
        "custom/left-arrow-light"
        "clock#2"
        "custom/left-arrow-dark"
        "clock#1"
      ];
    };
  };
}
