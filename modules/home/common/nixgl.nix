{ lib, config, nixgl, ... }:
{
  options.swarselsystems = {
    modules.nixgl = lib.mkEnableOption "nixgl settings";
    isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
    SecondaryGpuCard = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
  config = lib.mkIf config.swarselsystems.modules.nixgl {
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
