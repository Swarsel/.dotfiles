{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "snipeit"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy webProxyIf homeProxyIf dnsServer homeServiceAddress nginxAccessRules;
  # sopsFile = config.node.secretsDir + "/secrets2.yaml";
  inherit (config.swarselsystems) sopsFile;

  serviceDB = "snipeit";

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

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
    };

    services.snipe-it = {
      enable = true;
      appKeyFile = config.sops.secrets.snipe-it-appkey.path;
      appURL = "https://${serviceDomain}";
      hostName = serviceDomain;
      user = serviceUser;
      group = serviceGroup;
      dataDir = "/var/lib/snipeit";
      database = {
        user = serviceUser;
        port = mysqlPort;
        name = serviceDB;
        host = "localhost";
        createLocally = true;
      };
    };

    nodes = {
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
