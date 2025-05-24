{ lib, config, ... }:
{
  options.swarselsystems.modules.kdeconnect = lib.mkEnableOption "kdeconnect settings";
  config = lib.mkIf config.swarselsystems.modules.kdeconnect {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };

}
