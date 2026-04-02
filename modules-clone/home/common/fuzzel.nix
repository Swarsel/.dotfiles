{ lib, config, ... }:
{
  options.swarselmodules.fuzzel = lib.mkEnableOption "fuzzel settings";
  config = lib.mkIf config.swarselmodules.fuzzel {
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
