{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "opkssh"; user = "opksshuser"; group = "opksshuser"; }) serviceName serviceUser serviceGroup;

  kanidmDomain = globals.services.kanidm.domain;

  inherit (config.swarselsystems) mainUser;
  inherit (config.repo.secrets.local) persons;
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
          principal = builtins.head persons.${mainUser}.mailAddresses;
          inherit (config.services.opkssh.providers.kanidm) issuer;
        }
      ];
    };

  };

}
