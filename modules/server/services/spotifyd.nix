{
  flake.modules.nixos.spotifyd =
    { lib, config, confLib, ... }:
    let
      inherit (confLib.gen { name = "spotifyd"; port = 1025; }) servicePort serviceName serviceUser serviceGroup;
      inherit (confLib.static) routerServer;
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
              device_name = "SwarselSpot";
              backend = "pulseaudio";
              zeroconf_port = servicePort;
            };
          };
        };

        nodes.${routerServer}.networking.nftables.firewall.rules."fritzbox-to-${serviceName}" = {
          from = [ "untrusted" ];
          to = [ "vlan-services" ];
          extraLines = [
            "ip saddr 192.168.178.0/24 tcp dport ${toString servicePort} accept"
          ];
        };
      };

    }

  ;
}
