{
  flake.modules = {
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
          servicePort
          serviceName
          serviceDomain
          serviceAddress
          proxyAddress4
          proxyAddress6
          ;
        inherit (confLib.static)
          isHome
          webProxy
          homeWebProxy
          homeServiceAddress
          nginxAccessRules
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
            networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
            services = confLib.mkServiceGlobal {
              inherit
                serviceName
                serviceDomain
                proxyAddress4
                proxyAddress6
                isHome
                serviceAddress
                homeServiceAddress
                ;
            };
            monitoring.http = confLib.mkHttpMonitoring {
              inherit serviceName servicePort;
              expectedBodyRegex = ''"version":'';
            };
            dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
          };

          services.${serviceName} = {
            enable = true;
            host = "0.0.0.0";
            port = servicePort;
            # openFirewall = true;
            openRegistration = false;
          };

          nodes = {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                servicePort
                serviceDomain
                serviceName
                ;
              maxBody = 0;
            };
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit servicePort serviceDomain serviceName;
                maxBody = 0;
                extraConfig = nginxAccessRules;
                serviceAddress = homeServiceAddress;
              }
            );
          };

        };
      };

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
            enableZshIntegration = true;
            enableBashIntegration = true;
            settings = {
              auto_sync = true;
              sync_frequency = "5m";
              sync_address = "https://${atuinDomain}";
            };
          };
        };
      };
  };
}
