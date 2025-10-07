{ lib, config, ... }:
let
  servicePort = 1025;
  serviceName = "spotifyd";
  serviceUser = "spotifyd";
  serviceGroup = serviceUser;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    users.groups.${serviceGroup} = {
      gid = 65136;
    };

    users.users.${serviceUser} = {
      isSystemUser = true;
      uid = 65136;
      group = serviceGroup;
      extraGroups = [ "audio" "utmp" "pipewire" ];
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services.pipewire.systemWide = true;

    # https://github.com/Spotifyd/spotifyd/issues/1366
    networking.hosts."0.0.0.0" = [ "apresolve.spotify.com" ];

    # hacky way to enable multi-session
    # when another user connects, the service will crash and the new user will login
    systemd.services.spotifyd.serviceConfig.RestartSec = lib.mkForce 1;

    services.spotifyd = {
      enable = true;
      settings = {
        global = {
          dbus_type = "session";
          use_mpris = false;
          device = "sysdefault:CARD=PCH";
          # device = "default";
          device_name = "SwarselSpot";
          # backend = "pulseaudio";
          backend = "alsa";
          # mixer = "alsa";
          zeroconf_port = servicePort;
        };
      };
    };
  };

}
