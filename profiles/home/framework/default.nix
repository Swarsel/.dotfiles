{ lib, config, ... }:
{
  options.swarselprofiles.framework = lib.mkEnableOption "is this a framework brand host";
  config = lib.mkIf config.swarselprofiles.framework {
    swarselmodules = {
      optional = {
        framework = lib.mkDefault true;
      };
    };

  };

}
