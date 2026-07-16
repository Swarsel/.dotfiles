{
  flake.modules.homeManager.element = { globals, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "element-desktop" ];
      programs.element-desktop = {
        enable = true;
        settings = {
          UIFeature = {
            deactivate = false;
            feedback = false;
            passwordReset = false;
            registration = false;
            shareSocial = false;
            voip = false;
            widgets = false;
          };
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://${globals.services.matrix.domain}/";
            };
          };
        };
      };
    };
  };
}
