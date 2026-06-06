{
  flake.modules.nixos.invidious =
    { self, lib, config, globals, confLib, ... }:
    let
      inherit (confLib.gen { name = "invidious"; port = 3001; }) servicePort serviceName serviceUser serviceDomain serviceAddress proxyAddress4 proxyAddress6;
      inherit (confLib.static) isHome idmServer webProxy homeWebProxy homeServiceAddress nginxAccessRules;

      sopsFile = self + /secrets/general/invidious-companion.yaml;
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];

      config = {
        swarselsystems.enabledServerModules = [ "invidious" ];

        sops = {
          secrets = {
            invidious-companion-key = { inherit sopsFile; mode = "0444"; };
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

        topology.self.services.${serviceName} = {
          info = "https://${serviceDomain}";
        };

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
          monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; expectedBodyRegex = "Invidious"; };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        services.${serviceName} = {
          enable = true;
          port = 3001;
          domain = serviceDomain;
          sig-helper.enable = true;
          http3-ytproxy.enable = true;
          nginx.enable = true;
          extraSettingsFile = config.sops.templates.invidiousExtraSettings.path;
          settings = {
            invidious_companion = [
              {
                # private_url = "http://127.0.0.1:8282/companion";
                public_url = "https://${serviceDomain}/companion";
                private_url = "https://${serviceDomain}/companion";
              }
            ];
            db.user = serviceUser;
            external_port = 80;
            https_only = false;
            popular_enabled = false;
            default_user_preferences = {
              dark_mode = "dark";
              feed_menu = [
                "Subscriptions"
                "Playlists"
                "Trending"
              ];
              default_home = "Subscriptions";
              player_style = "youtube";
              quality = "dash";
              save_player_pos = true;
              local = true;
              extend_desc = true;
            };
          };
        };

        services.nginx.virtualHosts.${serviceDomain} = {
          enableACME = false;
          forceSSL = false;
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
                  useACMEHost = globals.domains.main;
                  forceSSL = true;
                  acmeRoot = null;
                  oauth2.enable = true;
                  oauth2.allowedGroups = [ "invidious_access" ];
                  inherit extraConfig;
                  locations = {
                    "/" = {
                      proxyPass = "http://${serviceName}";
                    };
                  };
                };
              };
            };
          in
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
            ${webProxy}.services.nginx = genNginx serviceAddress "";
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);

          };

      };

    }

  ;
}
