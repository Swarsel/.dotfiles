{ lib, ... }:
{
  options.swarselsystems.cpuCount = lib.mkOption {
    type = lib.types.int;
    default = 8;
  };
  options.swarselsystems.temperatureHwmon.isAbsolutePath = lib.mkEnableOption "absolute temperature path";
  options.swarselsystems.temperatureHwmon.path = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
  options.swarselsystems.temperatureHwmon.input-filename = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
}
