{ lib, config, inputs, ... }:
{
  options.swarselsystems = {
    isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
    SecondaryGpuCard = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
  config = {
    swarselsystems.enabledHomeModules = [ "nixgl" ];
    nixGL = lib.mkIf (!config.swarselsystems.isNixos) {
      inherit (inputs.nixgl) packages;
      defaultWrapper = lib.mkDefault "mesa";
      vulkan.enable = lib.mkDefault false;
      prime = lib.mkIf config.swarselsystems.isSecondaryGpu {
        card = config.swarselsystems.secondaryGpuCard;
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
