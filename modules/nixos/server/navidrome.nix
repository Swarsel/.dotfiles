{ pkgs, config, lib, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "navidrome"; port = 4040; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6 isHome isProxied homeProxy webProxy dnsServer homeProxyIf webProxyIf;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

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

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    services.snapserver = {
      enable = true;
      settings = {
        stream = {
          port = 1704;
          source = "pipe:///tmp/snapfifo?name=default";
          bind_to_address = "0.0.0.0";
        };
      };
    };

    systemd.services = {
      ${serviceName}.serviceConfig = {
        PrivateDevices = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        RestrictRealtime = lib.mkForce false;
        SystemCallFilter = lib.mkForce null;
        RootDirectory = lib.mkForce null;
      };
    };

    services.${serviceName} = {
      enable = true;
      # openFirewall = true;
      settings = {
        LogLevel = "debug";
        Address = "0.0.0.0";
        Port = servicePort;
        MusicFolder = "/Vault/Eternor/Music";
        PlaylistsPath = "./Playlists";
        AutoImportPlaylists = false;
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 24h";
        # MPVPath = "";
        # MPVCommandTemplate = "${pkgs.mpv}/bin/mpv --audio-device=%d --input-ipc-server=%s --no-audio-display --log-file=/tmp/mpv.log --pause %f";
        # MPVCmdTemplate = "${pkgs.mpv}/bin/mpv --no-audio-display --pause %f --input-ipc-server=%s --audio-channels=stereo --audio-samplerate=48000 --audio-format=s16 --ao=pcm --ao-pcm-file=/tmp/snapfifo --log-file=/tmp/mpv.log";
        ReverseProxyWhitelist = "0.0.0.0/0";
        ReverseProxyUserHeader = "X-User";
        Jukebox = {
          Enabled = true;
          Default = "default";
          Devices = [
            # use mpv --audio-device=help to get these
            [ "default" "alsa/sysdefault:CARD=PCH" ]
          ];
        };
        # Switch using --impure as these credential files are not stored within the flake
        # sops-nix is not supported for these which is why we need to resort to these
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

    nodes.${webProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          useACMEHost = globals.domains.main;

          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = true;
          oauth2.allowedGroups = [ "navidrome_access" ];
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
  };


}
