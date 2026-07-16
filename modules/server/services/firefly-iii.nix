{
  flake.modules.nixos.firefly-iii =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "firefly-iii";
          port = 80;
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

      nginxGroup = "nginx";

      inherit (config.swarselsystems) sopsFile;
      cfg = config.services.firefly-iii;
    in
    {
      imports = [
        self.modules.nixos.nginx
      ];
      config = {
        swarselsystems.enabledServerModules = [ "firefly-iii" ];
        # topology.self.services.${serviceName} = {
        #   name = "Firefly-III";
        #   info = "https://${serviceDomain}";
        #   icon = "${self}/files/topology-images/${serviceName}.png";
        # };
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
            expectedBodyRegex = "OK";
            hostHeader = serviceDomain;
            path = "/health";
          };
        };
        sops = {
          secrets = {
            "firefly-iii-app-key" = {
              inherit sopsFile;
              group = if cfg.enableNginx then nginxGroup else serviceGroup;
              mode = "0440";
              owner = serviceUser;
            };
          };
        };
        users = {
          users.${serviceUser} = {
            extraGroups = lib.mkIf cfg.enableNginx [ nginxGroup ];
            group = lib.mkForce serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds = {
            firefly-iii = confLib.mkIds 983;
          };
        };
        services = {
          ${serviceName} = {
            enable = true;
            dataDir = "/var/lib/${serviceName}";
            enableNginx = true;
            group = if cfg.enableNginx then nginxGroup else serviceGroup;
            settings = {
              APP_ENV = "local";
              APP_KEY_FILE = config.sops.secrets.firefly-iii-app-key.path;
              APP_URL = "https://${serviceDomain}";
              DB_CONNECTION = "sqlite";
              TRUSTED_PROXIES = "**";
              TZ = config.repo.secrets.common.location.timezone;
              # turning these on breaks api access using the waterfly app
              # AUTHENTICATION_GUARD = "remote_user_guard";
              # AUTHENTICATION_GUARD_HEADER = "X-User";
              # AUTHENTICATION_GUARD_EMAIL = "X-Email";
            };
            user = serviceUser;
            virtualHost = serviceDomain;
          };

          nginx = {
            virtualHosts = {
              "${serviceDomain}" = {
                locations = {
                  "/api" = {
                    # setOauth2Headers = false;
                    extraConfig = ''
                      index index.php;
                      try_files $uri $uri/ /index.php?$query_string;
                      add_header Access-Control-Allow-Methods 'GET, POST, HEAD, OPTIONS';
                    '';
                  };
                };
              };
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
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams = {
                ${serviceName} = {
                  servers = {
                    "${toAddress}:${builtins.toString servicePort}" = { };
                  };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations = {
                    "/" = {
                      proxyPass = "http://${serviceName}";
                    };
                    "/api" = {
                      bypassAuth = true;
                      proxyPass = "http://${serviceName}";
                      setOauth2Headers = false;
                    };
                  };
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "firefly_access" ];
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            {
              ${idmServer} = confLib.mkKanidmOauth2ProxyAccess {
                proxyGroup = "firefly_access";
                serviceName = "firefly";
              };
            }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules; }
          ];

      };
    }

  ;
}
