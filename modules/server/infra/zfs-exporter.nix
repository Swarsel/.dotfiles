{
  flake.modules.nixos.zfs-exporter =
    {
      lib,
      config,
      globals,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "zfs-exporter";
          port = 9134;
        })
        servicePort
        serviceName
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        globals = {
          services.${serviceName}.extraConfig = {
            port = servicePort;
          };
        };

        topology.self.services.${serviceName} = {
          name = serviceName;
          icon = "services.prometheus";
        };

        services.prometheus.exporters.zfs = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = servicePort;
        };

        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter ''
            prometheus.scrape "zfs" {
              targets    = [{"__address__" = "127.0.0.1:${toString servicePort}"}]
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "zfs"
            }
          ''
        );

        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          [
            {
              orgId = 1;
              name = "zfs";
              folder = "Infrastructure";
              interval = "1m";
              rules = [
                (confLib.mkGrafanaAlertRule {
                  uid = "zfs_pool_unhealthy";
                  title = "ZFS pool not online";
                  expr = "max by (host, pool) (zfs_pool_health)";
                  op = "gt";
                  threshold = 0;
                  forDuration = "5m";
                  summary = "ZFS pool {{ $labels.host }}:{{ $labels.pool }} is not ONLINE";
                })
              ];
            }
          ];
      };
    }

  ;
}
