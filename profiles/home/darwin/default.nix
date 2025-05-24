{ lib, config, ... }:
{
  options.swarselsystems.profiles.darwin = lib.mkEnableOption "is this a darwin host";
  config = lib.mkIf config.swarselsystems.profiles.darwin {
    swarselsystems.modules = {
      general = lib.mkDefault true;
    };
  };

}
