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
          extraGroups = [ "audio" "utmp" ];
        };
      };
    };


    hardware.enableAllFirmware = true;

    services.navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        Port = 4040;
        MusicFolder = "/media";
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 1d";
        # Insert these values locally as sops-nix does not work for them
        # LastFM.ApiKey = TEMPLATE;
        # LastFM.Secret = TEMPLATE;
        # Spotify.ID = TEMPLATE;
        # Spotify.Secret = TEMPLATE;
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
              proxyPass = "http://192.168.1.13:4040";
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
