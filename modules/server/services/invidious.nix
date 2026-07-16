{
  flake.modules.nixos.invidious =
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
          name = "invidious";
          port = 3001;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
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

      sopsFile = self + /secrets/general/invidious-companion.yaml;
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ "invidious" ];
        topology.self.services.${serviceName} = {
          info = "https://${serviceDomain}";
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
            alertFor = "30m";
            expectedBodyRegex = "Invidious";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            invidious-companion-key = {
              inherit sopsFile;
              mode = "0444";
            };
          };

          templates = {
            "invidiousExtraSettings" = {
              content = ''
                {"invidious_companion_key": "${config.sops.placeholder.invidious-companion-key}"}
              '';
              mode = "0444";
            };
          };
        };
        services = {
          ${serviceName} = {
            enable = true;
            domain = serviceDomain;
            extraSettingsFile = config.sops.templates.invidiousExtraSettings.path;
            http3-ytproxy.enable = true;
            nginx.enable = true;
            port = 3001;
            settings = {
              db.user = serviceUser;
              default_user_preferences = {
                dark_mode = "dark";
                default_home = "Subscriptions";
                extend_desc = true;
                feed_menu = [
                  "Subscriptions"
                  "Playlists"
                  "Trending"
                ];
                local = true;
                player_style = "youtube";
                quality = "dash";
                save_player_pos = true;
              };
              external_port = 80;
              https_only = false;
              invidious_companion = [
                {
                  private_url = "https://${serviceDomain}/companion";
                  # private_url = "http://127.0.0.1:8282/companion";
                  public_url = "https://${serviceDomain}/companion";
                }
              ];
              popular_enabled = false;
            };
            sig-helper.enable = true;
          };
          nginx.virtualHosts.${serviceDomain} = {
            enableACME = false;
            forceSSL = false;
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          { directory = "/var/lib/private/invidious"; }
        ];
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams = {
                ${serviceName} = {
                  servers = {
                    "${toAddress}:${builtins.toString 80}" = { };
                  };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations = {
                    "/" = {
                      proxyPass = "http://${serviceName}";
                    };
                  };
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "invidious_access" ];
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules); }
          ];

      };

    }

  ;
}
