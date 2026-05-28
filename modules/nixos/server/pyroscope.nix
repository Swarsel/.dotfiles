{ self, lib, config, confLib, ... }:
let
  inherit (confLib.gen {
    name = "pyroscope";
    port = 4040;
    dir = "/var/lib/private/pyroscope";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules wgProxyAccessRules;

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
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig.port = servicePort; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/ready"; expectedBodyRegex = "ready"; };
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

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

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
