{ lib, config, ... }:
let
  serviceDomain = "synki.swarsel.win";
  servicePort = 27701;
  serviceName = "ankisync";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    sops.secrets.swarsel = { owner = "root"; };

    topology.self.services.anki = {
      name = lib.mkForce "Anki Sync Server";
      info = "https://${serviceDomain}";
    };

    services.anki-sync-server = {
      enable = true;
      port = servicePort;
      address = "0.0.0.0";
      openFirewall = true;
      users = [
        {
          username = "Swarsel";
          passwordFile = config.sops.secrets.swarsel.path;
        }
      ];
    };

    services.nginx = {
      upstreams = {
        "${serviceName}" = {
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
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
