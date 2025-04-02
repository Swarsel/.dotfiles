{ lib, config, ... }:
{
  options.swarselsystems.modules.fuzzel = lib.mkEnableOption "fuzzel settings";
  config = lib.mkIf config.swarselsystems.modules.fuzzel {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          layer = "overlay";
          lines = "10";
          width = "40";
        };
        border.radius = "0";
      };
    };
  };
}
