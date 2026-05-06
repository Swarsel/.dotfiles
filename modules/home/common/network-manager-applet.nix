_:
{
  config = {
    swarselsystems.enabledHomeModules = [ "nm-applet" ];
    services.network-manager-applet.enable = true;
    xsession.preferStatusNotifierItems = true; # needed for indicator icon to show
  };
}
