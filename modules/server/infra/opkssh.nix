let
  redirectUris = [
    "http://localhost:3000/login-callback"
    "http://localhost:10001/login-callback"
    "http://localhost:11110/login-callback"
  ];
in
{
  flake.modules = {
    homeManager.opkssh =
      { globals, ... }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "opkssh" ];
          programs.opkssh = {
            enable = true;
            settings = {
              default_provider = "kanidm";

              providers = [
                {
                  alias = "kanidm";
                  client_id = "opkssh";
                  issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/opkssh";
                  redirect_uris = redirectUris;
                  scopes = "openid email profile";
                }
              ];
            };
          };
        };
      };
    nixos.opkssh =
      {
        config,
        confLib,
        globals,
        ...
      }:
      let
        inherit
          (confLib.gen {
            group = "opksshuser";
            name = "opkssh";
            user = "opksshuser";
          })
          serviceGroup
          serviceName
          serviceUser
          ;
        inherit (confLib.static) idmServer;
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "opkssh" ];
          users.persistentIds.opksshuser = confLib.mkIds 980;
          services.${serviceName} = {
            enable = true;
            authorizations = [
              {
                inherit (config.services.opkssh.providers.kanidm) issuer;
                principal = config.repo.secrets.common.mail.address4;
                user = "root";
              }
            ];
            group = serviceGroup;
            providers.kanidm = {
              clientId = serviceName;
              issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/${serviceName}";
              lifetime = "oidc";
            };
            user = serviceUser;
          };
          nodes = {
            ${idmServer}.services.kanidm.provision = {
              groups."opkssh.access" = { };
              systems.oauth2.opkssh = {
                displayName = "OPKSSH";
                enableLocalhostRedirects = true;
                originLanding = "http://localhost:3000";
                originUrl = [ "http://localhost:3000" ] ++ redirectUris;
                public = true;
                scopeMaps."opkssh.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
            };
          };

        };
      };
  };
}
