{ lib, config, ... }:
let
  servicePort = 1025;
  serviceName = "spotifyd";
  serviceUser = "spotifyd";
  serviceGroup = serviceUser;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {
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

    services.spotifyd = {
      enable = true;
      settings = {
        global = {
          dbus_type = "session";
          use_mpris = false;
          device = "sysdefault:CARD=PCH";
          device_name = "SwarselSpot";
          mixer = "alsa";
          zeroconf_port = servicePort;
        };
      };
    };
  };

}
