{
  flake.modules.nixos.nextcloud =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit (config.repo.secrets.local.nextcloud) adminuser;
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "nextcloud";
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

      nextcloudVersion = "33";

      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      imports = [
        self.modules.nixos.nginx
      ];
      config = {
        swarselsystems.enabledServerModules = [ "nextcloud" ];
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
            expectedBodyRegex = ''"installed":\s*true'';
            hostHeader = serviceDomain;
            path = "/status.php";
          };
        };
        sops.secrets = {
          kanidm-nextcloud = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = kanidmSopsFile;
          };
          nextcloud-admin-pw = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
        };
        users.persistentIds = {
          nextcloud = confLib.mkIds 990;
          redis-nextcloud = confLib.mkIds 976;
        };
        services = {
          ${serviceName} = {
            config = {
              inherit adminuser;
              adminpassFile = config.sops.secrets.nextcloud-admin-pw.path;
              dbtype = "sqlite";
            };
            enable = true;
            package = pkgs."nextcloud${nextcloudVersion}";
            configureRedis = true;
            datadir = "/var/lib/${serviceName}";
            extraApps = {
              inherit (pkgs."nextcloud${nextcloudVersion}Packages".apps)
                calendar
                contacts
                cospend
                forms
                mail
                phonetrack
                polls
                sociallogin
                tables
                tasks
                ;
            };
            extraAppsEnable = true;
            home = "/var/lib/${serviceName}";
            hostName = serviceDomain;
            https = true;
            maxUploadSize = "64G";
            settings = {
              overwriteprotocol = "https";
              trusted_proxies = [ "0.0.0.0" ];
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
            {
              directory = "/var/lib/redis-${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        nodes =
          let
            extraConfigLoc = ''
              proxy_request_buffering off;
              client_body_timeout     7200s;
              proxy_read_timeout      7200s;
              proxy_send_timeout      7200s;
              send_timeout            7200s;
            '';
          in
          lib.mkMerge [
            {
              ${idmServer} =
                lib.recursiveUpdate
                  (confLib.mkKanidmOidcSystem {
                    inherit kanidmSopsFile serviceDomain serviceName;
                    extraGroups = [ "nextcloud.admins" ];
                    originUrl = " https://${serviceDomain}/apps/sociallogin/custom_oidc/kanidm";
                  })
                  {
                    services.kanidm.provision.systems.oauth2.nextcloud = {
                      allowInsecureClientDisablePkce = true;
                      claimMaps.groups = {
                        joinType = "array";
                        valuesByGroup."nextcloud.admins" = [ "admin" ];
                      };
                    };
                  };
            }
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
    }

  ;
}
