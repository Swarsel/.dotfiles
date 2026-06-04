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
    nixGL = lib.mkIf (!config.swarselsystems.isNixos) ({
      inherit (inputs.nixgl) packages;
      defaultWrapper = "mesa";
      vulkan.enable = false;
      installScripts = [
        "mesa"
        "mesaPrime"
      ];
    } // lib.optionalAttrs config.swarselsystems.isSecondaryGpu {
      prime = {
        card = config.swarselsystems.secondaryGpuCard;
        installScript = "mesa";
      };
      offloadWrapper = "mesaPrime";
    });
  };
}
