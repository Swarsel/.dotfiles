{
  flake.modules.nixos.paperless =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "paperless";
          port = 28981;
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

      tikaPort = 9998;
      gotenbergPort = 3002;
      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "paperless" ];
        # networking.firewall.allowedTCPPorts = [ servicePort ];
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
            expectedBodyRegex = "Paperless";
            path = "/accounts/login/";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            kanidm-paperless.sopsFile = kanidmSopsFile;
            paperless-admin-pw = {
              inherit sopsFile;
              owner = serviceUser;
            };
          };
          templates."paperless-oidc.env".content = ''
            PAPERLESS_SOCIALACCOUNT_PROVIDERS='${
              builtins.toJSON {
                openid_connect = {
                  APPS = [
                    rec {
                      client_id = "paperless";
                      name = "Kanidm";
                      provider_id = "kanidm";
                      secret = config.sops.placeholder.kanidm-paperless;
                      settings.server_url = "https://${kanidmDomain}/oauth2/openid/${client_id}/.well-known/openid-configuration";
                    }
                  ];
                  OAUTH_PKCE_ENABLED = "True";
                };
              }
            }'
          '';
        };
        users = {
          users.${serviceUser}.extraGroups = [ "users" ];
          persistentIds.redis-paperless = confLib.mkIds 975;
        };
        services = {
          ${serviceName} = {
            enable = true;
            address = "0.0.0.0";
            dataDir = "/var/lib/${serviceName}";
            mediaDir = "/storage/Documents/${serviceName}";
            passwordFile = config.sops.secrets.paperless-admin-pw.path;
            port = servicePort;
            settings = {
              PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
              PAPERLESS_OCR_LANGUAGE = "deu+eng";
              PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
                invalidate_digital_signatures = true;
                optimize = 1;
                pdfa_image_compression = "lossless";
              };
              PAPERLESS_TIKA_ENABLED = "true";
              PAPERLESS_TIKA_ENDPOINT = "http://localhost:${builtins.toString tikaPort}";
              PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:${builtins.toString gotenbergPort}";
              PAPERLESS_URL = "https://${serviceDomain}";
              domain = serviceDomain;
            };
            user = serviceUser;
          };
          gotenberg = {
            enable = true;
            package = pkgs.gotenberg;
            bindIP = "127.0.0.1";
            chromium.package = pkgs.chromium;
            libreoffice.package = pkgs.libreoffice;
            port = gotenbergPort;
            timeout = "600s";
          };
          tika = {
            enable = true;
            enableOcr = true;
            listenAddress = "127.0.0.1";
            openFirewall = false;
            port = tikaPort;
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
              group = "redis-${serviceGroup}";
              user = "redis-${serviceUser}";
            }
            { directory = "/var/lib/private/tika"; }
            {
              directory = "/var/cache/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
            { directory = "/var/cache/private/tika"; }
          ];
        };
        systemd.services = {
          paperless-scheduler.serviceConfig.TimeoutStartSec = "30min";
          paperless-web.serviceConfig.EnvironmentFile = [
            config.sops.templates."paperless-oidc.env".path
          ];
        };
        nodes =
          let
            extraConfigLoc = ''
              proxy_connect_timeout   300;
              proxy_send_timeout      300;
              proxy_read_timeout      300;
              send_timeout            300;
            '';
          in
          lib.mkMerge [
            {
              ${idmServer} = confLib.mkKanidmOidcSystem {
                inherit kanidmSopsFile serviceDomain serviceName;
                originUrl = "https://${serviceDomain}/accounts/oidc/kanidm/login/callback/";
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
