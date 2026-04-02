{ lib, config, ... }:
{
  options.swarselmodules.kdeconnect = lib.mkEnableOption "kdeconnect settings";
  config = lib.mkIf config.swarselmodules.kdeconnect {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };

}
