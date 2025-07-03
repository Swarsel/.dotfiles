{ lib, config, ... }:
{
  options.swarselsystems.modules.programs = lib.mkEnableOption "small program modules config";
  config = lib.mkIf config.swarselsystems.modules.programs {
    programs = {
      dconf.enable = true;
      evince.enable = true;
      kdeconnect.enable = true;
    };
  };
}
