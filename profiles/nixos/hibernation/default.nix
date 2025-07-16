{ lib, config, ... }:
{
  options.swarselprofiles.hibernation = lib.mkEnableOption "is this a host using hibernation";
  config = lib.mkIf config.swarselprofiles.hibernation {
    swarselmodules = {
      optional = {
        hibernation = lib.mkDefault true;
      };
    };

  };

}
