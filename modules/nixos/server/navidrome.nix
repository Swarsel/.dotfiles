{ pkgs, lib, inputs, config, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
in
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
      # opengl.enable = true;
      enableAllFirmware = true;
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
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 24h";
        MPVPath = "${pkgs.mpv}/bin/mpv";
        MPVCommandTemplate = "mpv --audio-device=%d --no-audio-display --pause %f";
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
        LastFM.ApiKey = lib.swarselsystems.getSecret "${secretsDirectory}/navidrome/lastfm-secret";
        LastFM.Secret = lib.swarselsystems.getSecret "${secretsDirectory}/navidrome/lastfm-key";
        Spotify.ID = lib.swarselsystems.getSecret "${secretsDirectory}/navidrome/spotify-id";
        Spotify.Secret = lib.swarselsystems.getSecret "${secretsDirectory}/navidrome/spotify-secret";
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
