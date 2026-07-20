{
  flake.modules = {
    homeManager.opkssh =
      { globals, ... }:
      let
        moduleName = "opkssh";
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "opkssh" ];
          programs.${moduleName} = {
            enable = true;
            settings = {
              default_provider = "kanidm";

              providers = [
                {
                  alias = "kanidm";
                  client_id = "opkssh";
                  issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/opkssh";
                  redirect_uris = [
                    "http://localhost:3000/login-callback"
                    "http://localhost:10001/login-callback"
                    "http://localhost:11110/login-callback"
                  ];
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

        kanidmDomain = globals.services.kanidm.domain;

        inherit (config.swarselsystems) mainUser;
        mailAddress = config.repo.secrets.common.mail.address4;
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
                principal = mailAddress;
                user = mainUser;
              }
            ];
            group = serviceGroup;
            providers.kanidm = {
              clientId = serviceName;
              issuer = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
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
                originUrl = [
                  "http://localhost:3000"
                  "http://localhost:3000/login-callback"
                  "http://localhost:10001/login-callback"
                  "http://localhost:11110/login-callback"
                ];
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
