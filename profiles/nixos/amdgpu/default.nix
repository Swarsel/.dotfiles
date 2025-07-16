{ lib, config, ... }:
{
  options.swarselprofiles.amdgpu = lib.mkEnableOption "is this a host with amd gpu";
  config = lib.mkIf config.swarselprofiles.amdgpu {
    swarselmodules = {
      optional = {
        amdgpu = lib.mkDefault true;
      };
    };

  };

}
