{ lib, config, ... }:
let
  moduleName = "batsignal";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    services.${moduleName} = {
      enable = true;
      extraArgs = [
        "-W"
        " Consider charging the battery"
        "-C"
        " Battery is low; plug in charger now"
        "-D"
        " Device will lose power in a few seconds"
        "-c"
        "10"
        "-d"
        "5"
      ];
    };
  };

}
