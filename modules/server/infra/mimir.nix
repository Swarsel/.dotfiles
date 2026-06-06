{
  flake.modules.nixos.mimir =
    { lib, config, globals, confLib, ... }:
    let
      inherit (confLib.gen {
        name = "mimir";
        port = 9009;
        dir = "/var/lib/private/mimir";
      }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
      inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules wgProxyAccessRules;
      inherit (globals.services.alloy.extraConfig) otlpGrpcPort;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        topology.self.services.${serviceName}.info = "https://${serviceDomain}";

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig = { port = servicePort; host = config.node.name; }; };
          monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/services"; expectedBodyRegex = "Running"; failIfBodyMatchesRegex = "(Starting|Stopping|Failed|Terminated|New|Stuck)"; };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        networking.firewall.allowedTCPPorts = [ servicePort ];

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [{ directory = serviceDir; mode = "0700"; }];
        };

        services.${serviceName} = {
          enable = true;
          configuration = {
            multitenancy_enabled = false;

            server = {
              http_listen_address = "0.0.0.0";
              http_listen_port = servicePort;
              grpc_listen_port = 9095;
              log_level = "warn";
            };

            common.storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/data";
            };

            blocks_storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/blocks";
              bucket_store.sync_dir = "${serviceDir}/tsdb-sync";
              tsdb.dir = "${serviceDir}/tsdb";
            };

            compactor = {
              data_dir = "${serviceDir}/compactor";
              sharding_ring.kvstore.store = "memberlist";
            };

            distributor.ring.instance_addr = "127.0.0.1";

            ingester.ring = {
              instance_addr = "127.0.0.1";
              kvstore.store = "memberlist";
              replication_factor = 1;
            };

            ruler.rule_path = "${serviceDir}/rules";
            ruler_storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/ruler";
            };

            store_gateway.sharding_ring = {
              instance_addr = "127.0.0.1";
              replication_factor = 1;
            };

            limits.max_global_series_per_user = 0;
          };
        };

        systemd.services.mimir = {
          serviceConfig.RestartSec = lib.mkForce "60";
          environment = {
            OTEL_TRACES_EXPORTER = "otlp";
            OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
            OTEL_SERVICE_NAME = "mimir-${config.node.name}";
          };
        };

        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit serviceAddress servicePort serviceDomain serviceName;
              maxBody = 0;
              extraConfig = wgProxyAccessRules;
            };
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx {
              inherit servicePort serviceDomain serviceName;
              serviceAddress = homeServiceAddress;
              maxBody = 0;
              extraConfig = nginxAccessRules;
            });
            ${globals.general.monitoringServer}.services.grafana.provision = {
              datasources.settings.datasources = [{
                name = "Mimir";
                uid = "mimir";
                type = "prometheus";
                access = "proxy";
                url = confLib.mkAlloyPushUrl {
                  host = globals.general.monitoringServer;
                  domain = serviceDomain;
                  port = servicePort;
                  path = "/prometheus";
                };
                isDefault = true;
                jsonData = {
                  httpMethod = "POST";
                  manageAlerts = true;
                  prometheusType = "Mimir";
                  cacheLevel = "High";
                  incrementalQueryOverlapWindow = "10m";
                };
              }];
              alerting.rules.settings.groups = [{
                orgId = 1;
                name = "mimir";
                folder = "Infrastructure";
                interval = "1m";
                rules = [
                  (confLib.mkGrafanaAlertRule {
                    uid = "host_down";
                    title = "Host down";
                    expr = "max by (host) (up) or max by (host) (host_expected * 0)";
                    summary = "{{ $labels.host }} stopped reporting (no `up` series and `host_expected` fallback fired)";
                  })
                  (confLib.mkGrafanaAlertRule {
                    uid = "disk_filling";
                    title = "Disk above 80% used";
                    expr = ''max by (host, mountpoint) (100 - (node_filesystem_avail_bytes{fstype!~"tmpfs|.*tmpfs|overlay"} / node_filesystem_size_bytes * 100))'';
                    op = "gt";
                    threshold = 80;
                    forDuration = "10m";
                    severity = "warning";
                    summary = "{{ $labels.host }}:{{ $labels.mountpoint }} is more than 80% full";
                  })
                ];
              }];
            };
          }
          (lib.genAttrs (lib.attrNames globals.services.alloy.extraConfig.clients) (alloyHost:
            let
              isCentral = alloyHost == globals.general.monitoringServer;
            in
            {
              environment.etc = {
                "alloy/config.alloy".text = lib.mkAfter ''
                  prometheus.exporter.unix "node" {${lib.optionalString isCentral ''

                    textfile {
                      directory = "/etc/alloy/textfiles"
                    }
                  ''}}

                  prometheus.scrape "node" {
                    targets    = prometheus.exporter.unix.node.targets
                    forward_to = [prometheus.remote_write.mimir.receiver]
                    job_name   = "node"
                  }

                  prometheus.remote_write "mimir" {
                    endpoint {
                      url = "${confLib.mkAlloyPushUrl {
                        host = alloyHost;
                        domain = serviceDomain;
                        port = servicePort;
                        path = "/api/v1/push";
                      }}"
                    }
                    external_labels = {
                      host = "${alloyHost}",
                    }
                  }
                '';
                "alloy/textfiles/host_expected.prom" = lib.mkIf isCentral {
                  text = lib.concatStrings (map
                    (h: ''host_expected{host="${h}"} 1
                    '')
                    (lib.attrNames globals.hosts));
                };
                "alloy/textfiles/probe_expected.prom" = lib.mkIf isCentral {
                  text = lib.concatStrings (
                    map
                      (n: ''probe_expected{name="${n}",probe="http"} 1
                      '')
                      (lib.attrNames globals.monitoring.http)
                    ++ map
                      (n: ''probe_expected{name="${n}",probe="ping"} 1
                      '')
                      (lib.attrNames globals.monitoring.ping)
                  );
                };
              };
            }))
        ];
      };
    }

  ;
}
