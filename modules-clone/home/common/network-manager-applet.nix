{ lib, config, ... }:
{
  options.swarselmodules.nm-applet = lib.mkEnableOption "enable network manager applet for tray";
  config = lib.mkIf config.swarselmodules.nm-applet {
    services.network-manager-applet.enable = true;
    xsession.preferStatusNotifierItems = true; # needed for indicator icon to show
  };
}
