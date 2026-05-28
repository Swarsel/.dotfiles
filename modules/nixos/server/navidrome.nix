{ self, pkgs, config, lib, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "navidrome"; port = 4040; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf nginxAccessRules homeServiceAddress;
in
{
  imports = [
    "${self}/modules/nixos/server/pipewire.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "navidrome" ];


    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    users = {
      groups = {
        ${serviceGroup} = {
          gid = 61593;
        };
      };

      users = {
        ${serviceUser} = {
          isSystemUser = true;
          uid = 61593;
          group = serviceGroup;
          extraGroups = [ "audio" "utmp" "users" "pipewire" ];
        };
      };
    };

    hardware = {
      enableAllFirmware = lib.mkForce true;
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/ping";
        expectedBodyRegex = ''^\.$'';
        network = "local-${config.node.name}";
      };
    };

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
        wants = [ "pipewire.service" ];
        environment = {
          PIPEWIRE_RUNTIME_DIR = "/run/pipewire";
        };
        serviceConfig = {
          PrivateDevices = lib.mkForce false;
          PrivateUsers = lib.mkForce false;
          PrivateTmp = lib.mkForce false;
          RestrictRealtime = lib.mkForce false;
          SystemCallFilter = lib.mkForce null;
          RootDirectory = lib.mkForce null;
        };
      };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
    };

    services.${serviceName} = {
      enable = true;
      settings = {
        LogLevel = "debug";
        Address = "0.0.0.0";
        Port = servicePort;
        MusicFolder = "/storage/Music";
        PlaylistsPath = "./Playlists";
        AutoImportPlaylists = false;
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 24h";
        MPVPath = "${pkgs.mpv}/bin/mpv";
        ReverseProxyWhitelist = "0.0.0.0/0";
        ReverseProxyUserHeader = "X-User";
        Jukebox = {
          Enabled = true;
          Default = "default";
          Devices = [
            # use mpv --audio-device=help to get these
            [ "default" "pipewire" ]
          ];
        };
        LastFM = {
          inherit (config.repo.secrets.local.LastFM) ApiKey Secret;
        };
        Spotify = {
          inherit (config.repo.secrets.local.Spotify) ID Secret;
        };
        UILoginBackgroundUrl = "https://i.imgur.com/OMLxi7l.png";
        UIWelcomeMessage = "~SwarselSound~";
        EnableInsightsCollector = false;
      };
    };


    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes =
      let
        genNginx = toAddress: extraConfigPre: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;
              forceSSL = true;
              acmeRoot = null;
              oauth2 = {
                enable = true;
                allowedGroups = [ "navidrome_access" ];
              };
              extraConfig = extraConfigPre;
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
                    proxyPass = "http://${serviceName}";
                    proxyWebsockets = true;
                    inherit extraConfig;
                  };
                  "/share" = {
                    proxyPass = "http://${serviceName}";
                    proxyWebsockets = true;
                    setOauth2Headers = false;
                    bypassAuth = true;
                    inherit extraConfig;
                  };
                  "/rest" = {
                    proxyPass = "http://${serviceName}";
                    proxyWebsockets = true;
                    setOauth2Headers = false;
                    bypassAuth = true;
                    inherit extraConfig;
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
