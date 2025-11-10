{ self, lib, config, globals, ... }:
let
  sopsFile = self + /secrets/winters/secrets2.yaml;

  serviceDB = "snipeit";

  servicePort = 80;
  serviceName = "snipeit";
  serviceUser = "snipeit";
  serviceGroup = serviceUser;
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;

  mysqlPort = 3306;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    sops = {
      secrets = {
        snipe-it-appkey = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";
    globals.services.${serviceName}.domain = serviceDomain;

    services.snipe-it = {
      enable = true;
      appKeyFile = config.sops.secrets.snipe-it-appkey.path;
      appURL = "https://${serviceDomain}";
      hostName = serviceDomain;
      user = serviceUser;
      group = serviceGroup;
      dataDir = "/Vault/data/snipeit";
      database = {
        user = serviceUser;
        port = mysqlPort;
        name = serviceDB;
        host = "localhost";
        createLocally = true;
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
            };
          };
        };
      };
    };

  };

}
