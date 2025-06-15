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
        "$(serviceGroup}" = {
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

    services.navidrome = {
      enable = true;
      openFirewall = true;
      settings = {
        LogLevel = "debug";
        Address = "0.0.0.0";
        Port = servicePort;
        MusicFolder = "/Vault/Eternor/Music";
        PlaylistsPath = "./Playlists";
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
          locations = {
            "/" = {
              proxyPass = "http://navidrome";
              proxyWebsockets = true;
              extraConfig = ''
                auth_request /oauth2/auth;
                error_page 401 = /oauth2/sign_in;

                # pass information via X-User and X-Email headers to backend,
                # requires running with --set-xauthrequest flag (done by NixOS)
                auth_request_set $user   $upstream_http_x_auth_request_user;
                auth_request_set $email  $upstream_http_x_auth_request_email;
                proxy_set_header X-User  $user;
                proxy_set_header X-Email $email;

                # if you enabled --pass-access-token, this will pass the token to the backend
                auth_request_set $token  $upstream_http_x_auth_request_access_token;
                proxy_set_header X-Access-Token $token;

                # if you enabled --cookie-refresh, this is needed for it to work with auth_request
                auth_request_set $auth_cookie $upstream_http_set_cookie;
                add_header Set-Cookie $auth_cookie;
                proxy_redirect          http:// https://;
                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
                proxy_buffering         off;
                proxy_request_buffering off;
                client_max_body_size    0;
              '';
            };
            "/oauth2/" = {
              proxyPass = "http://oauth2-proxy";
              extraConfig = ''
                proxy_set_header X-Scheme                $scheme;
                proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
              '';
            };
            "= /oauth2/auth" = {
              proxyPass = "http://oauth2-proxy/oauth2/auth";
              extraConfig = ''
                internal;

                proxy_set_header X-Scheme         $scheme;
                # nginx auth_request includes headers but not body
                proxy_set_header Content-Length   "";
                proxy_pass_request_body           off;
              '';
            };
            "/share" = {
              proxyPass = "http://navidrome";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_redirect          http:// https://;
                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
                proxy_buffering         off;
                proxy_request_buffering off;
                client_max_body_size    0;
                proxy_set_header X-User  "";
                proxy_set_header X-Email "";
              '';
            };
            "/rest" = {
              proxyPass = "http://navidrome";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_redirect          http:// https://;
                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
                proxy_buffering         off;
                proxy_request_buffering off;
                client_max_body_size    0;
                proxy_set_header X-User  "";
                proxy_set_header X-Email "";
              '';
            };
          };
        };
      };
    };
  };


}
