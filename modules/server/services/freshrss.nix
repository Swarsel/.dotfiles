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

      inherit (config.swarselsystems) sopsFile;
    in
    {
      imports = [
        self.modules.nixos.nginx
      ];
      config = {
        swarselsystems.enabledServerModules = [ "freshrss" ];
        # topology.self.services.${serviceName} = {
        #   name = "FreshRSS";
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
            expectedBodyRegex = "FreshRSS";
            hostHeader = serviceDomain;
          };

        };
        sops = {
          secrets = {
            freshrss-pw = {
              inherit sopsFile;
              owner = serviceUser;
            };
            # kanidm-freshrss-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
            # freshrss-oidc-crypto-key = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
          };

          #   templates = {
          #     "freshrss-env" = {
          #       content = ''
          #         DATA_PATH=${config.services.freshrss.dataDir}
          #         OIDC_ENABLED=1
          #         OIDC_PROVIDER_METADATA_URL=https://${kanidmDomain}/.well-known/openid-configuration
          #         OIDC_CLIENT_ID=freshrss
          #         OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-freshrss-client}
          #         OIDC_CLIENT_CRYPTO_KEY=${config.sops.placeholder.oidc-crypto-key}
          #         OIDC_REMOTE_USER_CLAIM=preferred_username
          #         OIDC_SCOPES=openid groups email profile
          #         OIDC_X_FORWARDED_HEADERS=X-Forwarded-Host X-Forwarded-Port X-Forwarded-Proto
          #       '';
          #       owner = "freshrss";
          #       group = "freshrss";
          #       mode = "0440";
          #     };
          #   };
        };
        users = {
          users.${serviceUser} = {
            extraGroups = [ "users" ];
            group = serviceGroup;
            isSystemUser = true;
          };
          persistentIds = {
            freshrss = confLib.mkIds 986;
          };
        };
        users.groups.${serviceGroup} = { };
        services.${serviceName} =
          let
            inherit (config.repo.secrets.local.freshrss) defaultUser;
          in
          {
            inherit defaultUser;
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
        # systemd.services.freshrss-config.serviceConfig.EnvironmentFile = [
        #   config.sops.templates.freshrss-env.path
        # ];
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
            { ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules; }
          ];

      };
    }

  ;
}
