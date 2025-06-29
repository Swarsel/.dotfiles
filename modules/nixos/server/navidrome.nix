{ pkgs, config, lib, ... }:
let
  serviceDomain = "sound.swarsel.win";
  servicePort = 4040;
  serviceName = "navidrome";
  serviceUser = "navidrome";
  serviceGroup = serviceUser;
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {
    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

    users = {
      groups = {
        "${serviceGroup}" = {
          gid = 61593;
        };
      };

      users = {
        "${serviceUser}" = {
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

    networking.firewall.allowedTCPPorts = [ 4040 ];

    globals.services.${serviceName}.domain = serviceDomain;

    services.navidrome = {
      enable = true;
      openFirewall = true;
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
        MPVPath = "${pkgs.mpv}/bin/mpv";
        MPVCommandTemplate = "mpv --audio-device=%d --no-audio-display --pause %f";
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

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
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
                proxyPass = "http://navidrome";
                proxyWebsockets = true;
                inherit extraConfig;
              };
              "/share" = {
                proxyPass = "http://navidrome";
                proxyWebsockets = true;
                setOauth2Headers = false;
                bypassAuth = true;
                inherit extraConfig;
              };
              "/rest" = {
                proxyPass = "http://navidrome";
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
