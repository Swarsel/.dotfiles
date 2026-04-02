{ lib, config, ... }:
let
  moduleName = "obs-studio";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
    };
  };

}
