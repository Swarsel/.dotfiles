{
  flake.modules.nixos.radicale =
    {
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "radicale";
          port = 8000;
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
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;
      inherit (config.swarselsystems) sopsFile;

      cfg = config.services.${serviceName};
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "radicale" ];
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
            expectedBodyRegex = "Radicale Web Interface";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets.radicale-user = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };

          templates =
            let
              inherit (config.repo.secrets.local.radicale) user1;
            in
            {
              "radicale-users" = {
                content = ''
                  ${user1}:${config.sops.placeholder.radicale-user}
                '';
                group = serviceGroup;
                mode = "0440";
                owner = serviceUser;
              };
            };
        };
        users.persistentIds = {
          radicale = confLib.mkIds 982;
        };
        services.${serviceName} = {
          enable = true;
          rights = {
            calendars = {
              collection = "{user}/[^/]+";
              permissions = "rw";
              user = ".+";
            };
            principal = {
              collection = "{user}";
              permissions = "RW";
              user = ".+";
            };
            # all: match authenticated users only
            root = {
              collection = "";
              permissions = "R";
              user = ".+";
            };
          };
          settings = {
            auth = {
              htpasswd_encryption = "autodetect";
              htpasswd_filename = config.sops.templates.radicale-users.path;
              type = "htpasswd";
            };
            server = {
              hosts = [
                "0.0.0.0:${builtins.toString servicePort}"
                "[::]:${builtins.toString servicePort}"
              ];
            };
            storage = {
              filesystem_folder = "/var/lib/radicale/collections";
            };
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        systemd.tmpfiles.settings."10-radicale" = {
          "${cfg.settings.storage.filesystem_folder}" = {
            d = {
              group = serviceGroup;
              mode = "0750";
              user = serviceUser;
            };
          };
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 16;
              maxBodyUnit = "M";
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 16;
                maxBodyUnit = "M";
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
