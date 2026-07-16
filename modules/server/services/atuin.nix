{
  flake.modules = {
    homeManager.atuin =
      { globals, ... }:
      let
        atuinDomain = globals.services.atuin.domain;
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "atuin" ];
          programs.atuin = {
            enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
            settings = {
              auto_sync = true;
              sync_address = "https://${atuinDomain}";
              sync_frequency = "5m";
            };
          };
        };
      };
    nixos.atuin =
      {
        self,
        lib,
        confLib,
        ...
      }:
      let
        inherit
          (confLib.gen {
            name = "atuin";
            port = 8888;
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
      in
      {
        imports = [
          self.modules.nixos.postgresql
        ];
        config = {
          swarselsystems.enabledServerModules = [ "atuin" ];
          topology.self.services.${serviceName}.info = "https://${serviceDomain}";
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
              expectedBodyRegex = ''"version":'';
            };
            networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          };
          services.${serviceName} = {
            enable = true;
            host = "0.0.0.0";
            # openFirewall = true;
            openRegistration = false;
            port = servicePort;
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
      };
  };
}
