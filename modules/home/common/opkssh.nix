{ lib, config, globals, ... }:
let
  moduleName = "opkssh";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
      settings = {
        default_provider = "kanidm";

        providers = [
          {
            alias = "kanidm";
            issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/opkssh";
            client_id = "opkssh";
            scopes = "openid email profile";
            redirect_uris = [
              "http://localhost:3000/login-callback"
              "http://localhost:10001/login-callback"
              "http://localhost:11110/login-callback"
            ];
          }
        ];
      };
    };
  };

}
