{ self, lib, config, pkgs, globals, dns, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  inherit (confLib.gen { name = "kavita"; port = 8080; }) servicePort serviceName serviceUser serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

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

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services.${serviceName} = {
      enable = true;
      user = serviceUser;
      settings.Port = servicePort;
      tokenKeyFile = config.sops.secrets.kavita-token.path;
      dataDir = "/Vault/data/${serviceName}";
    };

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
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };
}
