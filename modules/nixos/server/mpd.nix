{ self, lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.server.mpd = lib.mkEnableOption "enable mpd on server";
  config = lib.mkIf config.swarselsystems.modules.server.mpd {
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

    topology.self.services.mpd = {
      name = "MPD";
      info = "http://localhost:3254";
      icon = "${self}/topology/images/mpd.png";
    };

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
