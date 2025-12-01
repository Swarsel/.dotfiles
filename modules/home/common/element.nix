{ lib, config, globals, ... }:
let
  moduleName = "element-desktop";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.element-desktop = {
      enable = true;
      settings = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://${globals.services.matrix.domain}/";
          };
        };
        UIFeature = {
          feedback = false;
          voip = false;
          widgets = false;
          shareSocial = false;
          registration = false;
          passwordReset = false;
          deactivate = false;
        };
      };
    };
  };

}
