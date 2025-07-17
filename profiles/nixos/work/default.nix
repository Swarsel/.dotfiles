{ lib, config, ... }:
{
  options.swarselprofiles.work = lib.mkEnableOption "is this a work host";
  config = lib.mkIf config.swarselprofiles.work {
    swarselmodules = {
      optional = {
        work = lib.mkDefault true;
      };
    };
    home-manager.users."${config.swarselsystems.mainUser}" = {
      swarselprofiles = {
        work = lib.mkDefault true;
      };
    };

  };

}
