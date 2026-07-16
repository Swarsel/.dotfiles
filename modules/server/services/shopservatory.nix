{
  flake-file.inputs.shopservatory = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "pre-commit-hooks";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:Swarsel/shopservatory";
  };

  flake.modules.nixos.shopservatory =
    {
      self,
      inputs,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/shopservatory";
          name = "shopservatory";
          port = 8480;
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
        scannerDropRules
        webProxy
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
        topology.self.services.${serviceName} = {
          icon = "services.not-available";
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
            expectedBodyRegex = "ok";
            path = "/healthz";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            kanidm-shopservatory = {
              group = serviceName;
              mode = "0440";
              owner = serviceName;
              sopsFile = kanidmSopsFile;
            };
            shopservatory-ebay-client-id = {
              inherit sopsFile;
              group = serviceName;
              mode = "0440";
              owner = serviceName;
            };
            shopservatory-ebay-client-secret = {
              inherit sopsFile;
              group = serviceName;
              mode = "0440";
              owner = serviceName;
            };
            shopservatory-telegram-token = {
              inherit sopsFile;
              group = serviceName;
              mode = "0440";
              owner = serviceName;
            };
            shopservatory-user-admin-password = {
              inherit sopsFile;
              group = serviceName;
              mode = "0440";
              owner = serviceName;
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
            group = serviceName;
            mode = "0440";
            owner = serviceName;
          };
        };
        users.persistentIds.${serviceName} = confLib.mkIds 987;
        services.shopservatory = {
          enable = true;
          browser.enable = true;
          environmentFile = config.sops.templates."shopservatory-env".path;
          flaresolverr.enable = true;
          settings = {
            users = [
              {
                admin = true;
                email = "admin@${globals.domains.main}";
                name = "admin";
              }
            ];
            currency.target = "EUR";
            oidc = {
              client_id = serviceName;
              issuer = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
              name = "kanidm";
            };
            scrape = {
              browser_proxy = "socks5://${globals.services."socks-proxy".serviceAddress}:${
                builtins.toString globals.services."socks-proxy".extraConfig.port
              }";
              default_interval = "5m";
            };
            server = {
              base_url = "https://${serviceDomain}";
              listen = "0.0.0.0:${builtins.toString servicePort}";
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceName;
            mode = "0750";
            user = serviceName;
          }
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = "https://${serviceDomain}/auth/callback";
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
              extraConfig = scannerDropRules;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = scannerDropRules + nginxAccessRules;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    };
}
