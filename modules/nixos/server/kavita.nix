{ self, lib, config, pkgs, ... }:
let
  servicePort = 8080;
  serviceName = "kavita";
  serviceUser = "kavita";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
    };

    sops.secrets.kavita = { owner = serviceUser; };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    topology.self.services.${serviceName} = {
      name = "Kavita";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };
    globals.services.${serviceName}.domain = serviceDomain;

    services.${serviceName} = {
      enable = true;
      user = serviceUser;
      settings.Port = servicePort;
      tokenKeyFile = config.sops.secrets.kavita.path;
      dataDir = "/Vault/data/${serviceName}";
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
