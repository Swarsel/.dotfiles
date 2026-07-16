{
  flake.modules.nixos.ankisync =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "ankisync";
          port = 27701;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;

      ankiUser = globals.user.name;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "ankisync" ];
        topology.self.services.anki = {
          icon = lib.mkForce "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = lib.mkForce "Anki Sync Server";
        };
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedStatus = 404;
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        sops.secrets.anki-pw = {
          inherit sopsFile;
          owner = "root";
        };
        services.anki-sync-server = {
          # openFirewall = true;
          users = [
            {
              passwordFile = config.sops.secrets.anki-pw.path;
              username = ankiUser;
            }
          ];
          enable = true;
          address = "0.0.0.0";
          port = servicePort;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [ { directory = "/var/lib/private/anki-sync-server"; } ];
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
