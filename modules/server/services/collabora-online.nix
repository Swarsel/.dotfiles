{
  flake.modules.nixos.collabora-online =
    {
      root,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "collabora-online";
          port = 9980;
          user = "cool";
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;

      inherit (config.swarselsystems) sopsFile;

      extraConfigLoc = ''
        proxy_read_timeout 36000s;
      '';
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "collabora-online" ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "Collabora Online";
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
            extra.extraConfig = {
              node = config.node.name;
              port = servicePort;
            };
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "wopi-discovery";
            path = "/hosting/discovery";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets.collabora-admin-password = { inherit sopsFile; };
          templates.collabora-env.content = ''
            username=admin
            password=${config.sops.placeholder.collabora-admin-password}
          '';
        };
        users.persistentIds.${serviceUser} = confLib.mkIds 1004;
        services.${serviceName} = {
          enable = true;
          package = pkgs.collabora-online;
          port = servicePort;
          settings = {
            server_name = serviceDomain;
            ssl = {
              enable = false;
              termination = true;
            };
          };
        };
        systemd.services.coolwsd.serviceConfig.EnvironmentFile = config.sops.templates.collabora-env.path;
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = lib.recursiveUpdate (confLib.genNginx {
              inherit
                extraConfigLoc
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
              proxyWebsockets = true;
            }) { virtualHosts.${serviceDomain}.locations."/".recommendedSecurityHeaders = false; };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              lib.recursiveUpdate (confLib.genNginx {
                inherit
                  extraConfigLoc
                  serviceDomain
                  serviceName
                  servicePort
                  ;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }) { virtualHosts.${serviceDomain}.locations."/".recommendedSecurityHeaders = false; }
            );
          }
        ];

      };
    }

  ;
}
