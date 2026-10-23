{
  flake.modules.nixos.audiobookshelf =
    {
      self,
      root,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/audiobookshelf";
          name = "audiobookshelf";
          port = 13378;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;

      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = serviceName;
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
            path = "/healthcheck";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets.kanidm-audiobookshelf = {
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
          sopsFile = kanidmSopsFile;
        };
        users = {
          users.${serviceUser}.extraGroups = [ "users" ];
          persistentIds.${serviceName} = confLib.mkIds 938;
        };
        services.${serviceName} = {
          enable = true;
          host = "0.0.0.0";
          port = servicePort;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = [
                "https://${serviceDomain}/auth/openid/callback"
                "https://${serviceDomain}/auth/openid/mobile-redirect"
              ];
            };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
