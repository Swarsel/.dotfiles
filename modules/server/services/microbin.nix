{
  flake.modules.nixos.microbin =
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
          name = "microbin";
          port = 8777;
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

      cfg = config.services.${serviceName};
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "microbin" ];
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
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "pasta-form";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            microbin-admin-password = {
              inherit sopsFile;
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
            };
            microbin-admin-username = {
              inherit sopsFile;
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
            };
            microbin-uploader-password = {
              inherit sopsFile;
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
            };
          };

          templates."microbin-env" = {
            content = ''
              MICROBIN_ADMIN_USERNAME="${config.sops.placeholder.microbin-admin-username}"
              MICROBIN_ADMIN_PASSWORD="${config.sops.placeholder.microbin-admin-password}"
              MICROBIN_UPLOADER_PASSWORD="${config.sops.placeholder.microbin-uploader-password}"
            '';
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
        };
        users = {
          users.${serviceUser} = {
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.${serviceName} = confLib.mkIds 964;
        };
        services.${serviceName} = {
          enable = true;
          dataDir = "/var/lib/microbin";
          passwordFile = config.sops.templates.microbin-env.path;
          settings = {
            MICROBIN_BIND = "0.0.0.0";
            MICROBIN_DEFAULT_EXPIRY = "1week";
            MICROBIN_DISABLE_TELEMETRY = true;
            MICROBIN_DISABLE_UPDATE_CHECKING = true;
            MICROBIN_EDITABLE = true;
            MICROBIN_ENABLE_BURN_AFTER = true;
            MICROBIN_ENABLE_READONLY = true;
            MICROBIN_ETERNAL_PASTA = true;
            MICROBIN_GC_DAYS = 30;
            MICROBIN_HIDE_FOOTER = true;
            MICROBIN_HIDE_HEADER = true;
            MICROBIN_HIDE_LOGO = true;
            MICROBIN_HIGHLIGHTSYNTAX = true;
            MICROBIN_LIST_SERVER = false;
            MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 256;
            MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 1024;
            MICROBIN_NO_FILE_UPLOAD = false;
            MICROBIN_NO_LISTING = false;
            MICROBIN_PORT = servicePort;
            MICROBIN_PRIVATE = true;
            MICROBIN_PUBLIC_PATH = "https://${serviceDomain}";
            MICROBIN_QR = true;
            MICROBIN_READONLY = true;
            MICROBIN_SHOW_READ_STATS = true;
            MICROBIN_THREADS = 1;
            MICROBIN_TITLE = "~SwarselScratch~";
          };
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = cfg.dataDir;
            group = serviceGroup;
            mode = "0700";
            user = serviceUser;
          }
        ];
        systemd.services = {
          ${serviceName}.serviceConfig = {
            DynamicUser = lib.mkForce false;
            Group = serviceGroup;
            User = serviceUser;
          };
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
              maxBody = 1;
              maxBodyUnit = "G";
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 1;
                maxBodyUnit = "G";
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };

    }

  ;
}
