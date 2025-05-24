{ lib, config, ... }:
{
  options.swarselsystems.modules.optional.amdgpu = lib.mkEnableOption "optional amd gpu settings";
  config = lib.mkIf config.swarselsystems.modules.optional.amdgpu {
    hardware = {
      amdgpu = {
        opencl.enable = true;
        amdvlk = {
          enable = true;
          support32Bit.enable = true;
        };
      };
    };
  };
}
