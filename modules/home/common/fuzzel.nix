_:
{
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
}
