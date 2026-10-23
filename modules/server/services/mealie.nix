{
  flake.modules.nixos.mealie =
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
          name = "mealie";
          port = 9000;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        notificationMail
        webProxy
        ;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
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
            expectedBodyRegex = ''"production":\s*true'';
            path = "/api/app/about";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            kanidm-mealie = {
              mode = "0400";
              sopsFile = kanidmSopsFile;
            };
            notification-mail-pw.sopsFile = notificationMail.sopsFile;
          };
          templates.mealie-env.content = ''
            OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-mealie}
            SMTP_PASSWORD=${config.sops.placeholder.notification-mail-pw}
          '';
        };
        services.${serviceName} = {
          enable = true;
          credentialsFile = config.sops.templates.mealie-env.path;
          settings = {
            ALLOW_SIGNUP = "false";
            BASE_URL = "https://${serviceDomain}";
            OIDC_ADMIN_GROUP = "${serviceName}.admins@${kanidmDomain}";
            OIDC_AUTH_ENABLED = "true";
            OIDC_AUTO_REDIRECT = "true";
            OIDC_CLIENT_ID = serviceName;
            OIDC_CONFIGURATION_URL = "https://${kanidmDomain}/oauth2/openid/${serviceName}/.well-known/openid-configuration";
            OIDC_GROUPS_CLAIM = "groups";
            OIDC_PROVIDER_NAME = "Kanidm";
            OIDC_SIGNUP_ENABLED = "true";
            OIDC_USER_GROUP = "${serviceName}.access@${kanidmDomain}";
            SMTP_AUTH_STRATEGY = "TLS";
            SMTP_FROM_EMAIL = notificationMail.address;
            SMTP_FROM_NAME = "Mealie";
            SMTP_HOST = notificationMail.host;
            SMTP_PORT = "587";
            SMTP_USER = notificationMail.address;
            TZ = config.repo.secrets.common.location.timezone;
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/private/${serviceName}";
              mode = "0700";
            }
          ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit kanidmSopsFile serviceDomain serviceName;
                  extraGroups = [ "${serviceName}.admins" ];
                  originUrl = "https://${serviceDomain}/login";
                })
                {
                  services.kanidm.provision.systems.oauth2.${serviceName}.scopeMaps."${serviceName}.access" =
                    lib.mkForce
                      [
                        "openid"
                        "email"
                        "profile"
                        "groups"
                      ];
                };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
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
                inherit serviceDomain serviceName servicePort;
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
