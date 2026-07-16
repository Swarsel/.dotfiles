{
  flake.modules.nixos.mimir =
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
          dir = "/var/lib/private/mimir";
          name = "mimir";
          port = 9009;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        wgProxyAccessRules
        ;
      inherit (globals.services.alloy.extraConfig) otlpGrpcPort;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
            extra.extraConfig = {
              host = config.node.name;
              port = servicePort;
            };
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "Running";
            failIfBodyMatchesRegex = "(Starting|Stopping|Failed|Terminated|New|Stuck)";
            path = "/services";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services.${serviceName} = {
          enable = true;
          configuration = {
            blocks_storage = {
              backend = "filesystem";
              bucket_store.sync_dir = "${serviceDir}/tsdb-sync";
              filesystem.dir = "${serviceDir}/blocks";
              tsdb.dir = "${serviceDir}/tsdb";
            };
            common.storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/data";
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
            limits.max_global_series_per_user = 0;
            multitenancy_enabled = false;
            ruler.rule_path = "${serviceDir}/rules";
            ruler_storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/ruler";
            };
            server = {
              grpc_listen_port = 9095;
              http_listen_address = "0.0.0.0";
              http_listen_port = servicePort;
              log_level = "warn";
            };
            store_gateway.sharding_ring = {
              instance_addr = "127.0.0.1";
              replication_factor = 1;
            };
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              mode = "0700";
            }
          ];
        };
        networking.firewall.allowedTCPPorts = [ servicePort ];
        systemd.services.mimir = {
          environment = {
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
            OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
            OTEL_SERVICE_NAME = "mimir-${config.node.name}";
            OTEL_TRACES_EXPORTER = "otlp";
          };
          serviceConfig.RestartSec = lib.mkForce "60";
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              extraConfig = wgProxyAccessRules;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
          {
            ${globals.general.monitoringServer}.services.grafana.provision = {
              alerting.rules.settings.groups = [
                {
                  folder = "Infrastructure";
                  interval = "1m";
                  name = "mimir";
                  orgId = 1;
                  rules = [
                    (confLib.mkGrafanaAlertRule {
                      expr = "max by (host) (up) or max by (host) (host_expected * 0)";
                      summary = "{{ $labels.host }} stopped reporting (no `up` series and `host_expected` fallback fired)";
                      title = "Host down";
                      uid = "host_down";
                    })
                    (confLib.mkGrafanaAlertRule {
                      expr = ''max by (host, mountpoint) (100 - (node_filesystem_avail_bytes{fstype!~"tmpfs|.*tmpfs|overlay"} / node_filesystem_size_bytes * 100))'';
                      forDuration = "10m";
                      op = "gt";
                      severity = "warning";
                      summary = "{{ $labels.host }}:{{ $labels.mountpoint }} is more than 80% full";
                      threshold = 80;
                      title = "Disk above 80% used";
                      uid = "disk_filling";
                    })
                  ];
                }
              ];
              datasources.settings.datasources = [
                {
                  access = "proxy";
                  isDefault = true;
                  jsonData = {
                    cacheLevel = "High";
                    httpMethod = "POST";
                    incrementalQueryOverlapWindow = "10m";
                    manageAlerts = true;
                    prometheusType = "Mimir";
                  };
                  name = "Mimir";
                  type = "prometheus";
                  uid = "mimir";
                  url = confLib.mkAlloyPushUrl {
                    domain = serviceDomain;
                    host = globals.general.monitoringServer;
                    path = "/prometheus";
                    port = servicePort;
                  };
                }
              ];
            };
          }
          (lib.genAttrs (lib.attrNames globals.services.alloy.extraConfig.clients) (
            alloyHost:
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
                      url = "${
                        confLib.mkAlloyPushUrl {
                          domain = serviceDomain;
                          host = alloyHost;
                          path = "/api/v1/push";
                          port = servicePort;
                        }
                      }"
                    }
                    external_labels = {
                      host = "${alloyHost}",
                    }
                  }
                '';
                "alloy/textfiles/host_expected.prom" = lib.mkIf isCentral {
                  text = lib.concatStrings (
                    map (h: ''
                      host_expected{host="${h}"} 1
                    '') (lib.attrNames globals.hosts)
                  );
                };
                "alloy/textfiles/probe_expected.prom" = lib.mkIf isCentral {
                  text = lib.concatStrings (
                    map (n: ''
                      probe_expected{name="${n}",probe="http"} 1
                    '') (lib.attrNames globals.monitoring.http)
                    ++ map (n: ''
                      probe_expected{name="${n}",probe="ping"} 1
                    '') (lib.attrNames globals.monitoring.ping)
                  );
                };
              };
            }
          ))
        ];
      };
    }

  ;
}
