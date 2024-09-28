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
      extraGroups = [ "audio" "utmp" "pipewire" ];
    };

    networking.firewall.allowedTCPPorts = [ 1025 ];

    services.pipewire.systemWide = true;

    services.spotifyd = {
      enable = true;
      settings = {
        global = {
          dbus_type = "session";
          use_mpris = false;
          device = "sysdefault:CARD=PCH";
          device_name = "SwarselSpot";
          mixer = "alsa";
          zeroconf_port = 1025;
        };
      };
    };
  };

}
