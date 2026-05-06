{ pkgs, ... }:
let
  moduleName = "swaylock";
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "swaylock" ];
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
