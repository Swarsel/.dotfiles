{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "snipeit"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6 isHome webProxy dnsServer;
  # sopsFile = config.node.secretsDir + "/secrets2.yaml";
  inherit (config.swarselsystems) sopsFile;

  serviceDB = "snipeit";

  mysqlPort = 3306;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    sops = {
      secrets = {
        snipe-it-appkey = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6 isHome;
    };

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

    nodes.${webProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          useACMEHost = globals.domains.main;

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
