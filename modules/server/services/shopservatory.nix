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
      root,
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

      piaNamespace = "pia";
      piaTunnel = config.services.pia-netns.tunnels.${piaNamespace};
      jpProxyPort = 1081;
      jpNetnsPort = 1080;
      serviceReadable = {
        group = serviceName;
        mode = "0440";
        owner = serviceName;
      };
    in
    {
      imports = [
        inputs.shopservatory.nixosModules.default
        self.modules.nixos.pia-netns
      ];
      config = {
        swarselsystems.enabledServerModules = [ "shopservatory" ];
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
          general.socksProxyConsumers = [ config.node.name ];
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "ok";
            path = "/healthz";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets =
            lib.genAttrs [
              "shopservatory-ebay-client-id"
              "shopservatory-ebay-client-secret"
              "shopservatory-telegram-token"
              "shopservatory-user-admin-password"
            ] (_: serviceReadable)
            // {
              kanidm-shopservatory = serviceReadable // {
                rekey.keyPrefix = confLib.kanidmSecrets;
              };
              pia = { };
            };

          templates.shopservatory-env = serviceReadable // {
            content = ''
              SHOPSERVATORY_TELEGRAM_TOKEN=${config.sops.placeholder.shopservatory-telegram-token}
              SHOPSERVATORY_EBAY_CLIENT_ID=${config.sops.placeholder.shopservatory-ebay-client-id}
              SHOPSERVATORY_EBAY_CLIENT_SECRET=${config.sops.placeholder.shopservatory-ebay-client-secret}
              SHOPSERVATORY_OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-shopservatory}
              SHOPSERVATORY_USER_ADMIN_PASSWORD=${config.sops.placeholder.shopservatory-user-admin-password}
            '';
          };
        };
        users.persistentIds = {
          ${serviceName} = confLib.mkIds 987;
          microsocks = confLib.mkIds 988;
        };
        services = {
          microsocks = {
            enable = true;
            ip = "127.0.0.1";
            port = jpNetnsPort;
          };
          pia-netns.tunnels.${piaNamespace} = {
            credentialsFile = config.sops.secrets.pia.path;
            forwards.shopservatory-jp-proxy = {
              idleTimeout = 120;
              listenAddress = "127.0.0.1";
              port = jpProxyPort;
              service = "microsocks.service";
              targetPort = jpNetnsPort;
            };
            region = "japan";
          };
          shopservatory = {
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
                issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/${serviceName}";
                name = "kanidm";
              };
              scrape = {
                browser_proxy = "socks5://${globals.services."socks-proxy".serviceAddress}:${
                  builtins.toString globals.services."socks-proxy".extraConfig.port
                }";
                default_interval = "5m";
                jp_proxy_url = "socks5://127.0.0.1:${builtins.toString jpProxyPort}";
              };
              server = {
                base_url = "https://${serviceDomain}";
                listen = "0.0.0.0:${builtins.toString servicePort}";
              };
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
        systemd.services.microsocks = {
          after = [ piaTunnel.unit ];
          bindsTo = [ piaTunnel.unit ];
          partOf = [ piaTunnel.unit ];
          requires = [ piaTunnel.unit ];
          serviceConfig = {
            BindReadOnlyPaths = [
              "/etc/netns/${piaNamespace}/resolv.conf:/etc/resolv.conf"
            ];
            NetworkNamespacePath = piaTunnel.netnsPath;
            PrivateNetwork = lib.mkForce false;
          };
          wantedBy = lib.mkForce [ piaTunnel.unit ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit serviceDomain serviceName;
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
