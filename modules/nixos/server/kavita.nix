{ self, lib, config, pkgs, globals, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  servicePort = 8080;
  serviceName = "kavita";
  serviceUser = "kavita";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
    };

    sops.secrets.kavita-token = { inherit sopsFile; owner = serviceUser; };

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
      tokenKeyFile = config.sops.secrets.kavita-token.path;
      dataDir = "/Vault/data/${serviceName}";
    };

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
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };
}
