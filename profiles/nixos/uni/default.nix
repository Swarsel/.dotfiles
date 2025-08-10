{ lib, config, ... }:
{
  options.swarselprofiles.uni = lib.mkEnableOption "is this a uni host";
  config = lib.mkIf config.swarselprofiles.uni {
    # swarselmodules = {
    #   optional = {
    #     uni = lib.mkDefault true;
    #   };
    # };
    home-manager.users."${config.swarselsystems.mainUser}" = {
      swarselprofiles = {
        uni = lib.mkDefault true;
      };
    };

  };

}
