{ self, lib, config, pkgs, ... }:
let
  serviceName = "kavita";
  serviceUser = "kavita";
  serviceDomain = "scroll.swarsel.win";
  servicePort = 8080;
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    users.users."${serviceUser}" = {
      extraGroups = [ "users" ];
    };

    sops.secrets.kavita = { owner = serviceUser; };

    networking.firewall.allowedTCPPorts = [ 8080 ];

    topology.self.services.kavita = {
      name = "Kavita";
      info = "https://${serviceDomain}";
      icon = "${self}/topology/images/kavita.png";
    };

    services.kavita = {
      enable = true;
      user = serviceUser;
      settings.Port = servicePort;
      tokenKeyFile = config.sops.secrets.kavita.path;
      dataDir = "/Vault/data/kavita";
    };

    nodes.moonside.services.nginx = {
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
