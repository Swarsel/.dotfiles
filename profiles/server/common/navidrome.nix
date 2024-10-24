{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.navidrome {
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
      # opengl.enable = true;
      enableAllFirmware = true;
    };

    networking.firewall.allowedTCPPorts = [ 4040 ];

    services.navidrome = {
      enable = true;
      openFirewall = true;
      settings = {
        LogLevel = "error";
        Address = "127.0.0.1";
        Port = 4040;
        MusicFolder = "/Vault/Eternor/Musik";
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 24h";
        MPVPath = "${pkgs.mpv}/bin/mpv";
        MPVCommandTemplate = "mpv --audio-device=%d --no-audio-display --pause %f";
        Jukebox = {
          Enabled = true;
          Default = "pch";
          Devices = [
            [ "pch" "alsa/sysdefault:CARD=PCH" ]
          ];
        };
        # Insert these values locally as sops-nix does not work for them
        LastFM.ApiKey = builtins.readFile /home/swarsel/api/lastfm-secret;
        LastFM.Secret = builtins.readFile /home/swarsel/api/lastfm-key;
        Spotify.ID = builtins.readFile /home/swarsel/api/spotify-id;
        Spotify.Secret = builtins.readFile /home/swarsel/api/spotify-secret;
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
                proxy_redirect          http:// https://;
                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
                proxy_buffering         off;
                proxy_request_buffering off;
                client_max_body_size    0;
              '';
            };
          };
        };
      };
    };
  };


}
