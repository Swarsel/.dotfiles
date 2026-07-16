{
  flake.modules.nixos.spotifyd =
    {
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "spotifyd";
          port = 1025;
        })
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static) routerServer;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "spotifyd" ];
        users = {
          users.${serviceUser} = {
            extraGroups = [
              "audio"
              "utmp"
              "pipewire"
            ];
            group = serviceGroup;
            isSystemUser = true;
            uid = 65136;
          };
          groups.${serviceGroup} = {
            gid = 65136;
          };
        };
        services = {
          pipewire.systemWide = true;
          spotifyd = {
            enable = true;
            settings = {
              global = {
                backend = "pulseaudio";
                dbus_type = "session";
                device_name = "SwarselSpot";
                use_mpris = false;
                zeroconf_port = servicePort;
              };
            };
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            { directory = "/var/cache/private/spotifyd"; }
          ];
        };
        networking = {
          firewall.allowedTCPPorts = [ servicePort ];
          # https://github.com/Spotifyd/spotifyd/issues/1366
          hosts."0.0.0.0" = [ "apresolve.spotify.com" ];
        };
        # hacky way to enable multi-session
        # when another user connects, the service will crash and the new user will login
        systemd.services.spotifyd.serviceConfig.RestartSec = lib.mkForce 1;
        nodes.${routerServer}.networking.nftables.firewall.rules."fritzbox-to-${serviceName}" = {
          extraLines = [
            "ip saddr 192.168.178.0/24 tcp dport ${toString servicePort} accept"
          ];
          from = [ "untrusted" ];
          to = [ "vlan-services" ];
        };
      };

    }

  ;
}
