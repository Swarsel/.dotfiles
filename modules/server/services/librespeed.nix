{
  flake.modules.nixos.librespeed =
    {
      root,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "librespeed";
          port = 8092;
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
        notificationMail
        webProxy
        ;

      extraConfigLoc = ''
        gzip off;
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "LibreSpeed";
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
            expectedBodyRegex = "LibreSpeed";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services.${serviceName} = {
          enable = true;
          downloadIPDB = false;
          frontend = {
            enable = true;
            contactEmail = notificationMail.address;
            servers = [
              {
                name = serviceDomain;
                server = "//${serviceDomain}";
              }
            ];
            settings.telemetry_level = "disabled";
          };
          settings.listen_port = servicePort;
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                extraConfigLoc
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
                inherit
                  extraConfigLoc
                  serviceDomain
                  serviceName
                  servicePort
                  ;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    };
}
