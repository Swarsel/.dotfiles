{ lib, config, pkgs, ... }:
let
  moduleName = "swaylock";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        screenshots = true;
        clock = true;
        effect-blur = "7x5";
        effect-vignette = "0.5:0.5";
        fade-in = "0.2";
      };
    };
  };

}
