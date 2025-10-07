{ lib, config, ... }:
{
  options.swarselmodules.optional.amdgpu = lib.mkEnableOption "optional amd gpu settings";
  config = lib.mkIf config.swarselmodules.optional.amdgpu {
    hardware = {
      amdgpu = {
        opencl.enable = true;
        initrd.enable = true;
        # amdvlk = {
        #   enable = true;
        #   support32Bit.enable = true;
        # };
      };
    };
  };
}
