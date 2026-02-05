{ lib, config, ... }:
let
  moduleName = "autotiling";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    services.${moduleName} = {
      enable = true;
      systemdTarget = "sway-session.target";
    };
  };

}
