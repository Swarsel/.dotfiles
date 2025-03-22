{ lib, config, nixgl, ... }:
{
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
}
