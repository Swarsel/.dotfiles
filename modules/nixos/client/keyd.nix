_:
{
  config = {
    services.keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              leftmeta = "overload(meta, macro(rightmeta+z))";
              rightmeta = "overload(meta, macro(rightmeta+z))";
            };
          };
        };
      };
    };
  };
}
