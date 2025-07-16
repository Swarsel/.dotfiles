{ lib, config, ... }:
{
  options.swarselmodules.mako = lib.mkEnableOption "mako settings";
  config = lib.mkIf config.swarselmodules.mako {
    services.mako = {
      enable = true;
      settings = {
        border-radius = 15;
        border-size = 1;
        default-timeout = 5000;
        ignore-timeout = 1;
        icons = 1;
        layer = "overlay";
        sort = "-time";
        height = 150;
        width = 300;
        "urgency=low" = {
          border-color = lib.mkForce "#cccccc";
        };
        "urgency=normal" = {
          border-color = lib.mkForce "#d08770";
        };
        "urgency=high" = {
          border-color = lib.mkForce "#bf616a";
          default-timeout = 3000;
        };
        "category=mpd" = {
          default-timeout = 2000;
          group-by = "category";
        };
      };
    };
  };

}
