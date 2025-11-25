{ lib, pkgs, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "immich"; port = 3001; }) servicePort serviceName serviceUser serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    users.users.${serviceUser} = {
      extraGroups = [ "video" "render" "users" ];
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

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
