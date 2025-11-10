{ lib, pkgs, config, globals, ... }:
let
  servicePort = 7745;
  serviceName = "homebox";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";
    globals.services.${serviceName}.domain = serviceDomain;

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
