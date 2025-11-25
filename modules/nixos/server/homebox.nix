{ lib, pkgs, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "homebox"; port = 7745; }) servicePort serviceName serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
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

    networking.firewall.allowedTCPPorts = [ servicePort ];

    nodes.${serviceProxy}.services.nginx = {
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
