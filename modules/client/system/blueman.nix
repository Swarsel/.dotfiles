{
  flake.modules = {
    homeManager.blueman-applet.config = {
      swarselsystems.enabledHomeModules = [ "blueman-applet" ];
      services.blueman-applet.enable = true;
    };
    nixos.blueman.config.services = {
      blueman.enable = true;
      hardware.bolt.enable = true;
    };
  };
}
