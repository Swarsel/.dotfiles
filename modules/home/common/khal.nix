{ pkgs, ... }:
let
  moduleName = "khal";
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "khal" ];
    programs.${moduleName} = {
      enable = true;
      package = pkgs.khal;
    };
  };

}
