{
  flake.modules.nixos.dawarich =
    {
      self,
      root,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/dawarich";
          name = "dawarich";
          port = 3000;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
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
        notificationMail
        webProxy
        ;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = serviceName;
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
            expectedBodyRegex = ''"status":\s*"ok"'';
            hostHeader = serviceDomain;
            path = "/api/v1/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            kanidm-dawarich.sopsFile = kanidmSopsFile;
            notification-mail-pw.sopsFile = notificationMail.sopsFile;
          };
          templates.dawarich-oidc-env.content = ''
            OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-dawarich}
          '';
        };
        users.persistentIds = {
          ${serviceName} = confLib.mkIds 936;
          "redis-${serviceName}" = confLib.mkIds 934;
        };
        services.${serviceName} = {
          enable = true;
          configureNginx = false;
          environment = {
            ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
            OIDC_CLIENT_ID = serviceName;
            OIDC_ISSUER = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
            OIDC_PKCE_ENABLED = "true";
            OIDC_PROVIDER_NAME = "Kanidm";
            OIDC_REDIRECT_URI = "https://${serviceDomain}/users/auth/openid_connect/callback";
            SMTP_DOMAIN = globals.domains.main;
          };
          extraEnvFiles = [ config.sops.templates.dawarich-oidc-env.path ];
          localDomain = serviceDomain;
          smtp = {
            inherit (notificationMail) host;
            fromAddress = "Dawarich <${notificationMail.address}>";
            passwordFile = config.sops.secrets.notification-mail-pw.path;
            port = 587;
            user = notificationMail.address;
          };
          webPort = servicePort;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              group = serviceGroup;
              mode = "0750";
              user = serviceUser;
            }
            {
              directory = "/var/lib/redis-${serviceName}";
              group = "redis-${serviceName}";
              user = "redis-${serviceName}";
            }
          ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = "https://${serviceDomain}/users/auth/openid_connect/callback";
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
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
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
