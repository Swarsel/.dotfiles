{ lib, config, ... }:
{
  options.swarselmodules.optional.amdcpu = lib.mkEnableOption "optional amd cpu settings";
  config = lib.mkIf config.swarselmodules.optional.amdcpu {
    hardware = {
      cpu.amd.updateMicrocode = true;
    };
  };
}
