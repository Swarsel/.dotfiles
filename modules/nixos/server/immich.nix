{ lib, pkgs, config, globals, ... }:
let
  servicePort = 3001;
  serviceUser = "immich";
  serviceName = "immich";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.hosts.winters.ipv4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    users.users.${serviceUser} = {
      extraGroups = [ "video" "render" "users" ];
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";
    globals.services.${serviceName}.domain = serviceDomain;

    services.${serviceName} = {
      enable = true;
      package = pkgs.immich;
      host = "0.0.0.0";
      port = servicePort;
      openFirewall = true;
      mediaLocation = "/Vault/Eternor/Immich"; # dataDir
      environment = {
        IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://localhost:3003";
      };
    };

    networking.firewall.allowedTCPPorts = [ 3001 ];

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
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size    0;

                proxy_http_version 1.1;
                proxy_set_header   Upgrade    $http_upgrade;
                proxy_set_header   Connection "upgrade";
                proxy_redirect     off;

                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout       600s;
              '';
            };
          };
        };
      };
    };

  };

}
