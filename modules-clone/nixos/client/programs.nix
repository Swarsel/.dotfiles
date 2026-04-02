{ lib, config, ... }:
{
  options.swarselmodules.programs = lib.mkEnableOption "small program modules config";
  config = lib.mkIf config.swarselmodules.programs {
    programs = {
      dconf.enable = true;
      evince.enable = true;
      kdeconnect.enable = true;
    };
  };
}
