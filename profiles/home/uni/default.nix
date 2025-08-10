{ lib, config, ... }:
{
  options.swarselprofiles.uni = lib.mkEnableOption "is this a uni host";
  config = lib.mkIf config.swarselprofiles.uni {
    swarselmodules = {
      optional = {
        uni = lib.mkDefault true;
      };
    };
  };

}
