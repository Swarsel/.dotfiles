{ lib, config, nixgl, ... }:
{
  options.swarselmodules.nixgl = lib.mkEnableOption "nixgl settings";
  options.swarselsystems = {
    isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
    SecondaryGpuCard = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
  config = lib.mkIf config.swarselmodules.nixgl {
    nixGL = lib.mkIf (!config.swarselsystems.isNixos) {
      inherit (nixgl) packages;
      defaultWrapper = lib.mkDefault "mesa";
      vulkan.enable = lib.mkDefault false;
      prime = lib.mkIf config.swarselsystem.isSecondaryGpu {
        card = config.swarselsystem.secondaryGpuCard;
        installScript = "mesa";
      };
      offloadWrapper = lib.mkIf config.swarselsystem.isSecondaryGpu "mesaPrime";
      installScripts = [
        "mesa"
        "mesaPrime"
      ];
    };
  };
}
