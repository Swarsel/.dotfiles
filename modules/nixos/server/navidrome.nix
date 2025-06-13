{ pkgs, config, lib, ... }:
{
  options.swarselsystems.modules.server.navidrome = lib.mkEnableOption "enable navidrome on server";
  config = lib.mkIf config.swarselsystems.modules.server.navidrome {
    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

    users = {
      groups = {
        navidrome = {
          gid = 61593;
        };
      };

      users = {
        navidrome = {
          isSystemUser = true;
          uid = 61593;
          group = "navidrome";
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
        Address = "127.0.0.1";
        Port = 4040;
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

    services.nginx = {
      virtualHosts = {
        "sound.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:4040";
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
              proxyPass = "http://localhost:4040";
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
              proxyPass = "http://localhost:4040";
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
