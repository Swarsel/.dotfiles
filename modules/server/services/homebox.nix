{
  flake.modules.nixos.homebox =
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
      inherit
        (confLib.gen {
          name = "homebox";
          port = 7745;
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

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ "homebox" ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "Homebox";
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
            expectedBodyRegex = ''"health":\s*true'';
            path = "/api/v1/status";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets.kanidm-homebox = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = kanidmSopsFile;
          };
          templates.homebox-oidc-env = {
            content = ''
              HBOX_OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-homebox}
            '';
            owner = serviceUser;
          };
        };
        users.persistentIds.homebox = confLib.mkIds 981;
        services.${serviceName} = {
          enable = true;
          package = pkgs.homebox;
          database.createLocally = true;
          settings = {
            HBOX_OIDC_BUTTON_TEXT = "Sign in with Kanidm";
            HBOX_OIDC_CLIENT_ID = serviceName;
            HBOX_OIDC_ENABLED = "true";
            HBOX_OIDC_ISSUER_URL = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
            HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
            HBOX_OPTIONS_TRUST_PROXY = "true";
            HBOX_STORAGE_CONN_STRING = "file:///var/lib/homebox";
            HBOX_STORAGE_PREFIX_PATH = ".data";
            HBOX_WEB_PORT = builtins.toString servicePort;
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
        systemd.services.${serviceName}.serviceConfig.EnvironmentFile =
          config.sops.templates.homebox-oidc-env.path;
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = "https://${serviceDomain}/api/v1/users/login/oidc/callback";
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
