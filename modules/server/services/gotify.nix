{
  flake.modules.nixos.gotify =
    {
      self,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/private/gotify-server";
          name = "gotify";
          port = 8080;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
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
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
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
            extra.extraConfig.port = servicePort;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "ok|green";
            path = "/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services = {
          ${serviceName} = {
            enable = true;
            environment = {
              GOTIFY_DATABASE_CONNECTION = "host=/run/postgresql user=gotify-server dbname=gotify-server sslmode=disable";
              GOTIFY_DATABASE_DIALECT = "postgres";
              GOTIFY_PASSSTRENGTH = 12;
              GOTIFY_PLUGINSDIR = "${serviceDir}/plugins";
              GOTIFY_SERVER_LISTENADDR = "0.0.0.0";
              GOTIFY_SERVER_PORT = servicePort;
              GOTIFY_UPLOADEDIMAGESDIR = "${serviceDir}/images";
            };
          };
          postgresql = {
            ensureDatabases = [ "gotify-server" ];
            ensureUsers = [
              {
                ensureDBOwnership = true;
                name = "gotify-server";
              }
            ];
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              mode = "0700";
            }
          ];
        };
        systemd.services.gotify-server.serviceConfig.RestartSec = lib.mkForce "60";
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 50;
              maxBodyUnit = "M";
              proxyWebsockets = true;
              # extraConfig = wgProxyAccessRules;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 50;
                maxBodyUnit = "M";
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
