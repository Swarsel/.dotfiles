{ lib, config, ... }:
{
  options.swarselsystems.modules.optional.amdcpu = lib.mkEnableOption "optional amd cpu settings";
  config = lib.mkIf config.swarselsystems.modules.optional.amdcpu {
    hardware = {
      cpu.amd.updateMicrocode = true;
    };
  };
}
