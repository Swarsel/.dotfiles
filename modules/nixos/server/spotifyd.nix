{ lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "spotifyd"; port = 1025; }) servicePort serviceUser serviceGroup;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "spotifyd" ];
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

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/cache/private/spotifyd"; }
      ];
    };

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
