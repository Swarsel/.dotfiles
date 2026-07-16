{
  flake.modules.nixos.zfs-exporter =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "zfs-exporter";
          port = 9134;
        })
        serviceName
        servicePort
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.prometheus";
          name = serviceName;
        };
        globals = {
          services.${serviceName}.extraConfig = {
            port = servicePort;
          };
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
              folder = "Infrastructure";
              interval = "1m";
              name = "zfs";
              orgId = 1;
              rules = [
                (confLib.mkGrafanaAlertRule {
                  expr = "max by (host, pool) (zfs_pool_health)";
                  forDuration = "5m";
                  op = "gt";
                  summary = "ZFS pool {{ $labels.host }}:{{ $labels.pool }} is not ONLINE";
                  threshold = 0;
                  title = "ZFS pool not online";
                  uid = "zfs_pool_unhealthy";
                })
              ];
            }
          ];
      };
    }

  ;
}
