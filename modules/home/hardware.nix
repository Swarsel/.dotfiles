{ lib, config, ... }:

let
  generateIcons = n: lib.concatStringsSep " " (builtins.map (x: "{icon" + toString x + "}") (lib.range 0 (n - 1)));
in
{
  options.swarselsystems.cpuCount = lib.mkOption {
    type = lib.types.int;
    default = 8;
  };
  options.swarselsystems.cpuString = lib.mkOption {
    type = lib.types.str;
    default = generateIcons config.swarselsystems.cpuCount;
    description = "The generated icons string for use by Waybar.";
    internal = true;
  };
}
