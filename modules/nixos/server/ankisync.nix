{ self, lib, config, globals, ... }:
let
  servicePort = 27701;
  serviceName = "ankisync";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  ankiUser = globals.user.name;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    sops.secrets.swarsel = { owner = "root"; };

    topology.self.services.${serviceName} = {
      name = lib.mkForce "Anki Sync Server";
      icon = "${self}/files/topology-images/${serviceName}.png";
      info = "https://${serviceDomain}";
    };

    globals.services.${serviceName}.domain = serviceDomain;

    services.anki-sync-server = {
      enable = true;
      port = servicePort;
      address = "0.0.0.0";
      openFirewall = true;
      users = [
        {
          username = ankiUser;
          passwordFile = config.sops.secrets.swarsel.path;
        }
      ];
    };

    services.nginx = {
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
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
