{ lib, config, ... }:
{
  options.swarselprofiles.optionals = lib.mkEnableOption "is this a host with optionals";
  config = lib.mkIf config.swarselprofiles.optionals {
    swarselmodules = {
      optional = {
        gaming = lib.mkDefault true;
        uni = lib.mkDefault true;
      };
    };
  };

}
