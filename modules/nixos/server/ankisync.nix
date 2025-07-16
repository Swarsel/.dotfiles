{ self, lib, config, globals, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  servicePort = 27701;
  serviceName = "ankisync";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  ankiUser = globals.user.name;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    sops.secrets.anki-pw = { inherit sopsFile; owner = "root"; };

    topology.self.services.anki = {
      name = lib.mkForce "Anki Sync Server";
      icon = lib.mkForce "${self}/files/topology-images/${serviceName}.png";
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
          passwordFile = config.sops.secrets.anki-pw.path;
        }
      ];
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
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
