{ lib, config, ... }:
{
  options.swarselsystems.profiles.hibernation = lib.mkEnableOption "is this a host using hibernation";
  config = lib.mkIf config.swarselsystems.profiles.hibernation {
    swarselsystems.modules = {
      optional = {
        hibernation = lib.mkDefault true;
      };
    };

  };

}
