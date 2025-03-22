{ lib, ... }:
{
  options.swarselsystems = {
    cpuCount = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
    isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
    SecondaryGpuCard = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    temperatureHwmon = {
      isAbsolutePath = lib.mkEnableOption "absolute temperature path";
      path = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      input-filename = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
  };
}
