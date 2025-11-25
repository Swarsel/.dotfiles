{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "ankisync"; port = 27701; }) servicePort serviceName serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  ankiUser = globals.user.name;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    sops.secrets.anki-pw = { inherit sopsFile; owner = "root"; };

    topology.self.services.anki = {
      name = lib.mkForce "Anki Sync Server";
      icon = lib.mkForce "${self}/files/topology-images/${serviceName}.png";
      info = "https://${serviceDomain}";
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

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
