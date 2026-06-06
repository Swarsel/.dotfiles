{
  flake.modules = {
    nixos.blueman = {
      config = {
        services = {
          blueman = {
            enable = true;
          };
          hardware.bolt.enable = true;
        };
      };
    };

    homeManager.blueman-applet = {
      config = {
        swarselsystems.enabledHomeModules = [ "blueman-applet" ];
        services.blueman-applet.enable = true;
      };
    };
  };
}
