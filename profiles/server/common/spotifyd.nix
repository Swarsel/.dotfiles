{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.spotifyd {
    users.groups.spotifyd = {
      gid = 65136;
    };

    users.users.spotifyd = {
      isSystemUser = true;
      uid = 65136;
      group = "spotifyd";
      extraGroups = [ "audio" "utmp" ];
    };

    networking.firewall.allowedTCPPorts = [ 1025 ];

    services.spotifyd = {
      enable = true;
      settings = {
        global = {
          dbus_type = "session";
          use_mpris = false;
          device = "default:CARD=PCH";
          device_name = "SwarselSpot";
          mixer = "alsa";
          zeroconf_port = 1025;
        };
      };
    };
  };

}
