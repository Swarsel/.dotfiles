{ lib, config, ... }:
{
  options.swarselprofiles.optionals = lib.mkEnableOption "is this a host with optionals";
  config = lib.mkIf config.swarselprofiles.optionals {
    swarselmodules = {
      optional = {
        gaming = lib.mkDefault true;
        virtualbox = lib.mkDefault true;
        nswitch-rcm = lib.mkDefault true;
      };
    };

    home-manager.users."${config.swarselsystems.mainUser}" = {
      swarselprofiles = {
        optionals = lib.mkDefault true;
      };
    };
  };

}
