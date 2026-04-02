{ lib, config, ... }:
let
  moduleName = "keyd";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "${moduleName} tools config";
  config = lib.mkIf config.swarselmodules.${moduleName} {
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
