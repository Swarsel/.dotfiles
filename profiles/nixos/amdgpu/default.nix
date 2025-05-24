{ lib, config, ... }:
{
  options.swarselsystems.profiles.amdgpu = lib.mkEnableOption "is this a host with amd gpu";
  config = lib.mkIf config.swarselsystems.profiles.amdgpu {
    swarselsystems.modules = {
      optional = {
        amdgpu = lib.mkDefault true;
      };
    };

  };

}
