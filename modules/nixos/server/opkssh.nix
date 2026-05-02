{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "opkssh"; user = "opksshuser"; group = "opksshuser"; }) serviceName serviceUser serviceGroup;
  inherit (confLib.static) idmServer;

  kanidmDomain = globals.services.kanidm.domain;

  inherit (config.swarselsystems) mainUser;
  mailAddress = config.repo.secrets.common.mail.address4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

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
      ${idmServer} =
        {
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

}
