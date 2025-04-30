{ lib, config, ... }:
{
  options.swarselsystems.profiles.framework = lib.mkEnableOption "is this a framework brand host";
  config = lib.mkIf config.swarselsystems.profiles.framework {
    swarselsystems.modules = {
      optional = {
        framework = lib.mkDefault true;
      };
    };

  };

}
