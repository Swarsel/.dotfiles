{
  flake.modules.nixos.firefox-syncserver =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "firefox-syncserver";
          port = 5000;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
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
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "firefox-syncserver" ];
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
            expectedBodyRegex = ''"status":"Ok"'';
            path = "/__heartbeat__";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            firefox-syncserver-secret = {
              inherit sopsFile;
              group = serviceGroup;
              mode = "0400";
              owner = serviceUser;
            };
          };

          templates = {
            "firefox-syncserver.env" = {
              content = ''
                SYNC_MASTER_SECRET=${config.sops.placeholder."firefox-syncserver-secret"}
              '';
              group = serviceGroup;
              mode = "0400";
              owner = serviceUser;
            };
          };
        };
        users = {
          users.firefox-syncserver = {
            group = "firefox-syncserver";
            isSystemUser = true;
          };
          groups.firefox-syncserver = { };
          persistentIds.firefox-syncserver = confLib.mkIds 949;
        };
        services = {
          ${serviceName} = {
            enable = true;
            secrets = config.sops.templates."firefox-syncserver.env".path;
            settings = {
              host = "0.0.0.0";
              port = servicePort;
              tokenserver.enabled = true;
            };
            singleNode = {
              enable = true;
              capacity = 1;
              enableNginx = false; # we handle it ourselves
              enableTLS = false; # we handle it ourselves
              hostname = serviceDomain; # we handle it ourselves however
              url = "https://${serviceDomain}";
            };
          };
          mysql.package = pkgs.mariadb;
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          { directory = "/var/lib/private/firefox-syncserver"; }
        ];
        systemd.services.firefox-syncserver.serviceConfig.StateDirectory = "firefox-syncserver";
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };

    }

  ;
}
