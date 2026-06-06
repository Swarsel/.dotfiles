{
  flake.modules.nixos.alloy =
    { lib, config, globals, confLib, ... }:
    let
      inherit (confLib.gen { name = "alloy"; port = 12345; })
        servicePort serviceName;
      inherit (confLib.static) isHome webProxy homeWebProxy inWgProxy inWgHome;

      otlpGrpcPort = 4317;
      otlpHttpPort = 4318;

      wgProxyHosts = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts;
      wgHomeHosts = globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts;

      mimirDomain = globals.services.mimir.domain;
      lokiDomain = globals.services.loki.domain;
      tempoDomain = globals.services.tempo.domain;
      pyroscopeDomain = globals.services.pyroscope.domain;

      config-alloy = ''
        logging {
          level  = "warn"
          format = "logfmt"
        }
      '';
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        globals = {
          services.${serviceName}.extraConfig = {
            httpPort = servicePort;
            inherit otlpGrpcPort otlpHttpPort;
            clients.${config.node.name} = true;
          };
          monitoring.hostNetworks.${config.node.name} = [ "local-${config.node.name}" ]
            ++ lib.optional isHome "home-lan"
            ++ lib.optional inWgHome "wgHome"
            ++ lib.optional inWgProxy "wgProxy"
            ++ lib.optional
            (globals.hosts.${config.node.name}.wanAddress4 != null
              || globals.hosts.${config.node.name}.wanAddress6 != null) "internet"
            ++ lib.mapAttrsToList (vlan: _: "${vlan}-vlan")
            (lib.filterAttrs
              (_: vlan: vlan ? hosts && vlan.hosts ? "${config.node.name}")
              (globals.networks.home-lan.vlans or { }));
        };

        networking.hosts =
          let
            proxyIp =
              if isHome && inWgHome
              then wgHomeHosts.${homeWebProxy}.ipv4
              else if inWgProxy
              then wgProxyHosts.${webProxy}.ipv4
              else null;
          in
          lib.optionalAttrs (proxyIp != null) {
            ${proxyIp} = [ mimirDomain lokiDomain tempoDomain pyroscopeDomain ];
          };

        environment = {
          etc."alloy/config.alloy".text = config-alloy;
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [{ directory = "/var/lib/private/alloy"; mode = "0700"; }];
          };
        };

        services.${serviceName} = {
          enable = true;
          extraFlags = [ "--server.http.listen-addr=127.0.0.1:${toString servicePort}" ];
        };

        systemd.services.alloy.serviceConfig = {
          RestartSec = lib.mkForce "60";
          AmbientCapabilities = [
            "CAP_BPF"
            "CAP_SYS_PTRACE"
            "CAP_NET_RAW"
            "CAP_CHECKPOINT_RESTORE"
            "CAP_DAC_READ_SEARCH"
            "CAP_PERFMON"
            "CAP_SYS_RESOURCE"
            "CAP_SYSLOG"
          ];
          CapabilityBoundingSet = [
            "CAP_BPF"
            "CAP_SYS_PTRACE"
            "CAP_NET_RAW"
            "CAP_CHECKPOINT_RESTORE"
            "CAP_DAC_READ_SEARCH"
            "CAP_PERFMON"
            "CAP_SYS_RESOURCE"
            "CAP_SYSLOG"
          ];
        };

      };
    }

  ;
}
