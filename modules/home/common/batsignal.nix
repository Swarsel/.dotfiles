{ lib, config, ... }:
let
  moduleName = "batsignal";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    services.${moduleName} = {
      enable = true;
    };
  };

}
