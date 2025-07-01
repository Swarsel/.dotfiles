{ lib, config, ... }:
let
  servicePort = 8888;
  serviceName = "atuin";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";
    globals.services.${serviceName}.domain = serviceDomain;

    services.${serviceName} = {
      enable = true;
      host = "0.0.0.0";
      port = servicePort;
      openFirewall = true;
      openRegistration = false;
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size    0;
              '';
            };
          };
        };
      };
    };

  };

}
