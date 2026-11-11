{
  flake.modules.nixos.freshrss =
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
          name = "freshrss";
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

    in
    {
      imports = [
        self.modules.nixos.nginx
      ];
      config = {
        swarselsystems.enabledServerModules = [ "freshrss" ];
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
            expectedBodyRegex = "FreshRSS";
            hostHeader = serviceDomain;
          };

        };
        sops.secrets.freshrss-pw.owner = serviceUser;
        users = {
          users.${serviceUser} = {
            extraGroups = [ "users" ];
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.freshrss = confLib.mkIds 986;
        };
        services.${serviceName} = {
          inherit (config.repo.secrets.local.freshrss) defaultUser;
          enable = true;
          authType = "form";
          baseUrl = "https://${serviceDomain}";
          dataDir = "/var/lib/freshrss";
          passwordFile = config.sops.secrets.freshrss-pw.path;
          virtualHost = serviceDomain;
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
                ${serviceName}.servers = {
                  "${toAddress}:${builtins.toString servicePort}" = { };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations = {
                    "/".proxyPass = "http://${serviceName}";
                    "/api" = {
                      bypassAuth = true;
                      proxyPass = "http://${serviceName}";
                      setOauth2Headers = false;
                    };
                  };
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "ttrss_access" ];
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            {
              ${idmServer} = confLib.mkKanidmOauth2ProxyAccess {
                inherit serviceName;
                proxyGroup = "ttrss_access";
              };
            }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules); }
          ];

      };
    };
}
