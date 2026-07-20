{
  flake.modules.nixos.kavita =
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
          name = "kavita";
          port = 8080;
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
      config = {
        swarselsystems.enabledServerModules = [ "kavita" ];
        # networking.firewall.allowedTCPPorts = [ servicePort ];
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
            expectedBodyRegex = "<title>Kavita</title>";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets = {
          kanidm-kavita = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = kanidmSopsFile;
          };
          kavita-token = {
            inherit sopsFile;
            owner = serviceUser;
          };
        };
        users = {
          users.${serviceUser}.extraGroups = [ "users" ];
          persistentIds.kavita = confLib.mkIds 995;
        };
        services.${serviceName} = {
          enable = true;
          dataDir = "/var/lib/${serviceName}";
          settings = {
            OpenIdConnectSettings = {
              Authority = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
              ClientId = serviceName;
              CustomScopes = [ ];
              Secret = "@OIDC_SECRET@";
            };
            Port = servicePort;
          };
          tokenKeyFile = config.sops.secrets.kavita-token.path;
          user = serviceUser;
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
        systemd.services.${serviceName} = {
          preStart = lib.mkAfter ''
            ${pkgs.replace-secret}/bin/replace-secret '@OIDC_SECRET@' \
              "''${CREDENTIALS_DIRECTORY}/oidc-secret" \
              '/var/lib/${serviceName}/config/appsettings.json'
          '';
          serviceConfig.LoadCredential = [ "oidc-secret:${config.sops.secrets.kanidm-kavita.path}" ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = "https://${serviceDomain}/signin-oidc";
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
