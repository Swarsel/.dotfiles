{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.mpd {
    users = {
      groups = {
        mpd = { };
      };

      users = {
        mpd = {
          isSystemUser = true;
          group = "mpd";
          extraGroups = [ "audio" "utmp" ];
        };
      };
    };

    sops = {
      secrets.mpdpass = { owner = "mpd"; };
    };

    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

    services.mpd = {
      enable = true;
      musicDirectory = "/media";
      user = "mpd";
      group = "mpd";
      network = {
        port = 3254;
        listenAddress = "any";
      };
      credentials = [
        {
          passwordFile = config.sops.secrets.mpdpass.path;
          permissions = [
            "read"
            "add"
            "control"
            "admin"
          ];
        }
      ];
    };
  };

}
