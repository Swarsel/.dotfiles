{ globals, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "element-desktop" ];
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
