{ lib, config, ... }:
{
  options.swarselsystems.profiles.amdcpu = lib.mkEnableOption "is this a host with amd cpu";
  config = lib.mkIf config.swarselsystems.profiles.amdcpu {
    swarselsystems.modules = {
      optional = {
        amdcpu = lib.mkDefault true;
      };
    };

  };

}
