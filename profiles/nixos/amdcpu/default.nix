{ lib, config, ... }:
{
  options.swarselprofiles.amdcpu = lib.mkEnableOption "is this a host with amd cpu";
  config = lib.mkIf config.swarselprofiles.amdcpu {
    swarselmodules = {
      optional = {
        amdcpu = lib.mkDefault true;
      };
    };

  };

}
