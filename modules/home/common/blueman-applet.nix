{ lib, config, ... }:
{
  options.swarselmodules.blueman-applet = lib.mkEnableOption "enable blueman applet for tray";
  config = lib.mkIf config.swarselmodules.blueman-applet {
    services.blueman-applet.enable = true;
  };
}
