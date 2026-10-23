{
  flake.modules.nixos.readeck =
    {
      self,
      root,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/private/readeck";
          name = "readeck";
          port = 8085;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
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

      inherit (config.swarselsystems) sopsFile;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "readeck" ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
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
            expectedBodyRegex = "Readeck";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            kanidm-readeck.sopsFile = kanidmSopsFile;
            notification-mail-pw.sopsFile = notificationMail.sopsFile;
            readeck-secret-key = { inherit sopsFile; };
          };
          templates.readeck-env.content = ''
            READECK_AUTH_OIDC_PROVIDERS_0_CLIENT_SECRET=${config.sops.placeholder.kanidm-readeck}
            READECK_MAIL_PASSWORD=${config.sops.placeholder.notification-mail-pw}
            READECK_SECRET_KEY=${config.sops.placeholder.readeck-secret-key}
          '';
        };
        services.${serviceName} = {
          enable = true;
          package = pkgs.readeck;
          environmentFile = config.sops.templates.readeck-env.path;
          settings = {
            auth.oidc.providers = [
              {
                client_id = serviceName;
                groups = [
                  [
                    "admin"
                    "admin"
                  ]
                  [
                    "user"
                    "user"
                  ]
                ];
                name = "Kanidm";
                provisioning = true;
                url = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
              }
            ];
            email = {
              inherit (notificationMail) host;
              encryption = "starttls";
              from = "Readeck <${notificationMail.address}>";
              from_noreply = "Readeck <${notificationMail.address}>";
              port = 587;
              username = notificationMail.address;
            };
            main = {
              data_directory = "/var/lib/${serviceName}/data";
              log_format = "text";
            };
            server = {
              host = "0.0.0.0";
              port = servicePort;
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0700";
          }
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit kanidmSopsFile serviceDomain serviceName;
                  extraGroups = [ "readeck.admins" ];
                  originUrl = "https://${serviceDomain}/login/oidc";
                })
                {
                  services.kanidm.provision.systems.oauth2.${serviceName}.claimMaps.groups = {
                    joinType = "array";
                    valuesByGroup = {
                      "readeck.access" = [ "user" ];
                      "readeck.admins" = [ "admin" ];
                    };
                  };
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
