{ lib, config, ... }:
let
  moduleName = "autotiling";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    swarselservices.${moduleName} = {
      enable = true;
      systemdTarget = config.wayland.systemd.target;
    };
  };

}
