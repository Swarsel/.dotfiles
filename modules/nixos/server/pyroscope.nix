{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen {
    name = "pyroscope";
    port = 4040;
    dir = "/var/lib/private/pyroscope";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules wgProxyAccessRules;

  memberlistPort = 7948;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

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
        extraConfig.port = servicePort;
      };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/ready";
        expectedBodyRegex = "ready";
        network = "local-${config.node.name}";
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = serviceDir; mode = "0700"; }];
    };

    services.${serviceName} = {
      enable = true;
      settings = {
        target = "all";
        multitenancy_enabled = false;
        analytics.reporting_enabled = false;
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = servicePort;
          grpc_listen_port = 9098;
          log_level = "warn";
        };
        storage = {
          backend = "filesystem";
          filesystem.dir = "${serviceDir}/data";
        };
        pyroscopedb.data_path = "${serviceDir}/pyroscope";
        memberlist.bind_port = memberlistPort;
      };
    };

    systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";

    globals.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx {
        inherit serviceAddress servicePort serviceDomain serviceName;
        maxBody = 0;
        extraConfig = wgProxyAccessRules;
      };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx {
        inherit servicePort serviceDomain serviceName;
        serviceAddress = homeServiceAddress;
        maxBody = 0;
        extraConfig = nginxAccessRules;
      });
    };
  };
}
