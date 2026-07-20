{
  flake.modules.nixos.navidrome =
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
          name = "navidrome";
          port = 4040;
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
    in
    {
      imports = [
        self.modules.nixos.server-pipewire
      ];
      config = {
        swarselsystems.enabledServerModules = [ "navidrome" ];
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
            expectedBodyRegex = ''^\.$'';
            path = "/ping";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        users = {
          users = {
            ${serviceUser} = {
              extraGroups = [
                "audio"
                "utmp"
                "users"
                "pipewire"
              ];
              group = serviceGroup;
              isSystemUser = true;
              uid = 61593;
            };
          };
          groups = {
            ${serviceGroup}.gid = 61593;
          };
        };
        services.${serviceName} = {
          enable = true;
          settings = {
            Address = "0.0.0.0";
            AutoImportPlaylists = false;
            EnableInsightsCollector = false;
            EnableSharing = true;
            EnableTranscodingConfig = true;
            Jukebox = {
              Default = "default";
              Devices = [
                # use mpv --audio-device=help to get these
                [
                  "default"
                  "pipewire"
                ]
              ];
              Enabled = true;
            };
            LastFM = {
              inherit (config.repo.secrets.local.LastFM) ApiKey Secret;
            };
            LogLevel = "debug";
            MPVPath = "${pkgs.mpv}/bin/mpv";
            MusicFolder = "/storage/Music";
            PlaylistsPath = "./Playlists";
            Port = servicePort;
            ReverseProxyUserHeader = "X-User";
            ReverseProxyWhitelist = "0.0.0.0/0";
            ScanSchedule = "@every 24h";
            Scanner.GroupAlbumReleases = true;
            Spotify = {
              inherit (config.repo.secrets.local.Spotify) ID Secret;
            };
            UILoginBackgroundUrl = "https://i.imgur.com/OMLxi7l.png";
            UIWelcomeMessage = "~SwarselSound~";
          };
        };
        environment = {
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/${serviceName}";
                group = serviceGroup;
                user = serviceUser;
              }
            ];
          };
          systemPackages = with pkgs; [
            pciutils
            alsa-utils
            mpv
          ];
        };
        hardware.enableAllFirmware = lib.mkForce true;
        # services.snapserver = {
        #   enable = true;
        #   settings = {
        #     stream = {
        #       port = 1704;
        #       source = "pipe:///tmp/snapfifo?name=default";
        #       bind_to_address = "0.0.0.0";
        #     };
        #   };
        # };
        systemd.services = {
          ${serviceName} = {
            after = [ "pipewire.service" ];
            environment.PIPEWIRE_RUNTIME_DIR = "/run/pipewire";
            serviceConfig = {
              PrivateDevices = lib.mkForce false;
              PrivateTmp = lib.mkForce false;
              PrivateUsers = lib.mkForce false;
              RestrictRealtime = lib.mkForce false;
              RootDirectory = lib.mkForce null;
              SystemCallFilter = lib.mkForce null;
            };
            wants = [ "pipewire.service" ];
          };
        };
        nodes =
          let
            genNginx = toAddress: extraConfigPre: {
              upstreams = {
                ${serviceName}.servers = {
                  "${toAddress}:${builtins.toString servicePort}" = { };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  acmeRoot = null;
                  extraConfig = extraConfigPre;
                  forceSSL = true;
                  locations =
                    let
                      extraConfig = ''
                        proxy_redirect          http:// https://;
                        proxy_read_timeout      600s;
                        proxy_send_timeout      600s;
                        proxy_buffering         off;
                        proxy_request_buffering off;
                        client_max_body_size    0;
                      '';
                    in
                    {
                      "/" = {
                        inherit extraConfig;
                        proxyPass = "http://${serviceName}";
                        proxyWebsockets = true;
                      };
                      "/rest" = {
                        inherit extraConfig;
                        bypassAuth = true;
                        proxyPass = "http://${serviceName}";
                        proxyWebsockets = true;
                        setOauth2Headers = false;
                      };
                      "/share" = {
                        inherit extraConfig;
                        bypassAuth = true;
                        proxyPass = "http://${serviceName}";
                        proxyWebsockets = true;
                        setOauth2Headers = false;
                      };
                    };
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "navidrome_access" ];
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
