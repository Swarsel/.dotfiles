{ lib, config, ... }:
{
  options.swarselsystems.profiles.work = lib.mkEnableOption "is this a work host";
  config = lib.mkIf config.swarselsystems.profiles.work {
    swarselsystems.modules = {
      optional = {
        work = lib.mkDefault true;
      };
    };

  };

}
