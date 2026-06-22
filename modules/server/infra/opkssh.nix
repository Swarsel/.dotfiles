{
  flake.modules = {
    nixos.opkssh =
      {
        config,
        globals,
        confLib,
        ...
      }:
      let
        inherit
          (confLib.gen {
            name = "opkssh";
            user = "opksshuser";
            group = "opksshuser";
          })
          serviceName
          serviceUser
          serviceGroup
          ;
        inherit (confLib.static) idmServer;

        kanidmDomain = globals.services.kanidm.domain;

        inherit (config.swarselsystems) mainUser;
        mailAddress = config.repo.secrets.common.mail.address4;
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "opkssh" ];

          users.persistentIds = {
            opksshuser = confLib.mkIds 980;
          };

          services.${serviceName} = {
            enable = true;
            user = serviceUser;
            group = serviceGroup;
            providers = {
              kanidm = {
                lifetime = "oidc";
                issuer = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
                clientId = serviceName;
              };
            };
            authorizations = [
              {
                user = mainUser;
                principal = mailAddress;
                inherit (config.services.opkssh.providers.kanidm) issuer;
              }
            ];
          };

          nodes = {
            ${idmServer} = {
              services.kanidm.provision = {
                groups = {
                  "opkssh.access" = { };
                };
                systems.oauth2.opkssh = {
                  displayName = "OPKSSH";
                  originUrl = [
                    "http://localhost:3000"
                    "http://localhost:3000/login-callback"
                    "http://localhost:10001/login-callback"
                    "http://localhost:11110/login-callback"
                  ];
                  originLanding = "http://localhost:3000";
                  public = true;
                  enableLocalhostRedirects = true;
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
      };
  };
}
