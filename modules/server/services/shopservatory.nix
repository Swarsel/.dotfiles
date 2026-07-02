{
  flake-file.inputs.shopservatory = {
    url = "github:Swarsel/shopservatory";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.shopservatory =
    {
      self,
      lib,
      config,
      globals,
      confLib,
      inputs,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "shopservatory";
          port = 8480;
          dir = "/var/lib/shopservatory";
        })
        servicePort
        serviceName
        serviceDomain
        serviceDir
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
        scannerDropRules
        ;

      inherit (config.swarselsystems) sopsFile;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      imports = [
        inputs.shopservatory.nixosModules.default
      ];

      config = {
        swarselsystems.enabledServerModules = [ "shopservatory" ];

        users.persistentIds.${serviceName} = confLib.mkIds 987;

        sops = {
          secrets = {
            shopservatory-telegram-token = {
              inherit sopsFile;
              owner = serviceName;
              group = serviceName;
              mode = "0440";
            };
            shopservatory-ebay-client-id = {
              inherit sopsFile;
              owner = serviceName;
              group = serviceName;
              mode = "0440";
            };
            shopservatory-ebay-client-secret = {
              inherit sopsFile;
              owner = serviceName;
              group = serviceName;
              mode = "0440";
            };
            shopservatory-user-admin-password = {
              inherit sopsFile;
              owner = serviceName;
              group = serviceName;
              mode = "0440";
            };
            kanidm-shopservatory = {
              sopsFile = kanidmSopsFile;
              owner = serviceName;
              group = serviceName;
              mode = "0440";
            };
          };

          templates."shopservatory-env" = {
            content = ''
              SHOPSERVATORY_TELEGRAM_TOKEN=${config.sops.placeholder.shopservatory-telegram-token}
              SHOPSERVATORY_EBAY_CLIENT_ID=${config.sops.placeholder.shopservatory-ebay-client-id}
              SHOPSERVATORY_EBAY_CLIENT_SECRET=${config.sops.placeholder.shopservatory-ebay-client-secret}
              SHOPSERVATORY_OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-shopservatory}
              SHOPSERVATORY_USER_ADMIN_PASSWORD=${config.sops.placeholder.shopservatory-user-admin-password}
            '';
            owner = serviceName;
            group = serviceName;
            mode = "0440";
          };
        };

        services.shopservatory = {
          enable = true;
          browser.enable = true;
          flaresolverr.enable = true;
          environmentFile = config.sops.templates."shopservatory-env".path;
          settings = {
            server = {
              listen = "0.0.0.0:${builtins.toString servicePort}";
              base_url = "https://${serviceDomain}";
            };
            currency.target = "EUR";
            scrape = {
              default_interval = "5m";
              browser_proxy = "socks5://${globals.services."socks-proxy".serviceAddress}:${builtins.toString globals.services."socks-proxy".extraConfig.port}";
            };
            users = [
              {
                name = "admin";
                email = "admin@${globals.domains.main}";
                admin = true;
              }
            ];
            oidc = {
              issuer = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
              client_id = serviceName;
              name = "kanidm";
            };
          };
        };

        topology.self.services.${serviceName} = {
          name = lib.swarselsystems.toCapitalized serviceName;
          info = "https://${serviceDomain}";
          icon = "services.not-available";
        };

        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            user = serviceName;
            group = serviceName;
            mode = "0750";
          }
        ];

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
            path = "/healthz";
            expectedBodyRegex = "ok";
          };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        nodes = {
          ${idmServer} = confLib.mkKanidmOidcSystem {
            inherit serviceName serviceDomain kanidmSopsFile;
            originUrl = "https://${serviceDomain}/auth/callback";
          };
          ${webProxy}.services.nginx = confLib.genNginx {
            inherit
              serviceAddress
              serviceName
              serviceDomain
              servicePort
              ;
            extraConfig = scannerDropRules;
          };
          ${homeWebProxy}.services.nginx = lib.mkIf isHome (
            confLib.genNginx {
              inherit serviceName serviceDomain servicePort;
              serviceAddress = homeServiceAddress;
              extraConfig = scannerDropRules + nginxAccessRules;
            }
          );
        };
      };
    };
}
