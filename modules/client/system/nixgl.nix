{
  flake.modules.homeManager.nixgl =
    {
      inputs,
      config,
      lib,
      nixosConfig ? null,
      ...
    }:
    {
      options.swarselsystems = {
        SecondaryGpuCard = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
      };
      config = {
        swarselsystems.enabledHomeModules = [ "nixgl" ];
        nixGL = lib.mkIf (nixosConfig == null) (
          {
            inherit (inputs.nixgl) packages;
            defaultWrapper = "mesa";
            installScripts = [
              "mesa"
              "mesaPrime"
            ];
            vulkan.enable = false;
          }
          // lib.optionalAttrs config.swarselsystems.isSecondaryGpu {
            offloadWrapper = "mesaPrime";
            prime = {
              card = config.swarselsystems.secondaryGpuCard;
              installScript = "mesa";
            };
          }
        );
      };
    };
}
