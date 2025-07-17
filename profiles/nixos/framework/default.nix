{ lib, config, ... }:
{
  options.swarselprofiles.framework = lib.mkEnableOption "is this a framework brand host";
  config = lib.mkIf config.swarselprofiles.framework {
    swarselmodules = {
      optional = {
        framework = lib.mkDefault true;
      };
    };
    home-manager.users."${config.swarselsystems.mainUser}" = {
      swarselprofiles = {
        framework = lib.mkDefault true;
      };
    };

  };

}
