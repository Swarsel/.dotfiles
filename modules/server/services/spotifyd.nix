{
  flake.modules.nixos.spotifyd =
    {
      config,
      lib,
      pkgs,
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
          groups.${serviceGroup}.gid = 65136;
        };
        services = {
          pipewire.systemWide = true;
          spotifyd = {
            enable = true;
            settings.global = {
              backend = "pulseaudio";
              dbus_type = "session";
              device_name = "SwarselSpot";
              use_mpris = false;
              zeroconf_port = servicePort;
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
        systemd = {
          services = {
            spotifyd.serviceConfig.RestartSec = lib.mkForce 1;
            spotifyd-watchdog = {
              path = with pkgs; [
                gnugrep
                iproute2
                systemd
              ];
              script = ''
                pid=$(systemctl show --property MainPID --value spotifyd.service)
                if [ "$pid" -eq 0 ]; then exit 0; fi
                if ! ss -Htnp state established '( dport = :443 or dport = :4070 or dport = :80 )' | grep -q "pid=$pid,"; then
                  systemctl restart spotifyd.service
                fi
              '';
              serviceConfig.Type = "oneshot";
            };
          };
          timers.spotifyd-watchdog = {
            timerConfig = {
              OnBootSec = "10m";
              OnUnitActiveSec = "10m";
            };
            wantedBy = [ "timers.target" ];
          };
        };
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
