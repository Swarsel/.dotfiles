{
  flake.modules.nixos.mealie =
    {
      self,
      lib,
      config,
      globals,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "mealie";
          port = 9000;
        })
        servicePort
        serviceName
        serviceDomain
        serviceAddress
        proxyAddress4
        proxyAddress6
        ;
      inherit (confLib.static)
        isHome
        webProxy
        homeWebProxy
        idmServer
        homeServiceAddress
        nginxAccessRules
        ;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        topology.self.services.${serviceName} = {
          info = "https://${serviceDomain}";
        };

        sops = {
          secrets.kanidm-mealie = {
            sopsFile = kanidmSopsFile;
            mode = "0400";
          };
          templates.mealie-oidc-env.content = ''
            OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-mealie}
          '';
        };

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal {
            inherit
              serviceName
              serviceDomain
              proxyAddress4
              proxyAddress6
              isHome
              serviceAddress
              homeServiceAddress
              ;
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            path = "/api/app/about";
            expectedBodyRegex = ''"production":\s*true'';
          };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/private/${serviceName}";
              mode = "0700";
            }
          ];
        };

        services.${serviceName} = {
          enable = true;
          credentialsFile = config.sops.templates.mealie-oidc-env.path;
          settings = {
            ALLOW_SIGNUP = "false";
            BASE_URL = "https://${serviceDomain}";
            TZ = config.repo.secrets.common.location.timezone;

            OIDC_AUTH_ENABLED = "true";
            OIDC_PROVIDER_NAME = "Kanidm";
            OIDC_CONFIGURATION_URL = "https://${kanidmDomain}/oauth2/openid/${serviceName}/.well-known/openid-configuration";
            OIDC_CLIENT_ID = serviceName;
            OIDC_USER_GROUP = "${serviceName}.access@${kanidmDomain}";
            OIDC_ADMIN_GROUP = "${serviceName}.admins@${kanidmDomain}";
            OIDC_AUTO_REDIRECT = "true";
            OIDC_SIGNUP_ENABLED = "true";
            OIDC_GROUPS_CLAIM = "groups";
          };
        };

        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit serviceName serviceDomain kanidmSopsFile;
                  originUrl = "https://${serviceDomain}/login";
                  extraGroups = [ "${serviceName}.admins" ];
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
                servicePort
                serviceDomain
                serviceName
                ;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit servicePort serviceDomain serviceName;
                maxBody = 0;
                extraConfig = nginxAccessRules;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    }

  ;
}
