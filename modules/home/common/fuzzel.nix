_:
{
  config = {
    swarselsystems.enabledHomeModules = [ "fuzzel" ];
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
