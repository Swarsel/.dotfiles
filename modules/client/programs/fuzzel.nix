{
  flake.modules.homeManager.fuzzel.config = {
    swarselsystems.enabledHomeModules = [ "fuzzel" ];
    programs.fuzzel = {
      enable = true;
      settings = {
        border.radius = "0";
        main = {
          layer = "overlay";
          lines = "10";
          width = "40";
        };
      };
    };
  };
}
