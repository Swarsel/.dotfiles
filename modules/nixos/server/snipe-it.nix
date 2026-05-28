{ lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "snipeit"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules;
  # sopsFile = config.node.secretsDir + "/secrets2.yaml";
  inherit (config.swarselsystems) sopsFile;

  serviceDB = "snipeit";

  mysqlPort = 3306;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "snipeit" ];

    sops = {
      secrets = {
        snipe-it-appkey = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; expectedBodyRegex = "Snipe-IT"; };
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

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
