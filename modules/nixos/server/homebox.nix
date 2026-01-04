{ self, lib, pkgs, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "homebox"; port = 7745; }) servicePort serviceName serviceDomain serviceAddress proxyAddress4 proxyAddress6 isHome isProxied homeProxy webProxy dnsServer homeProxyIf webProxyIf;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    topology.self.services.${serviceName} = {
      name = "Homebox";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    services.${serviceName} = {
      enable = true;
      package = pkgs.dev.homebox;
      database.createLocally = true;
      settings = {
        HBOX_WEB_PORT = builtins.toString servicePort;
        HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
        HBOX_STORAGE_CONN_STRING = "file:///Vault/data/homebox";
        HBOX_STORAGE_PREFIX_PATH = ".data";
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

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
