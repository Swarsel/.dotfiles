{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen {
    name = "tempo";
    port = 14318;
    dir = "/var/lib/private/tempo";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules wgProxyAccessRules;
  inherit (globals.services.alloy.extraConfig) otlpGrpcPort otlpHttpPort;

  tempoHttpApiPort = 3200;
  tempoOtlpGrpcPort = 14317;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort tempoHttpApiPort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig = { port = servicePort; host = config.node.name; }; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName; servicePort = tempoHttpApiPort; path = "/ready"; expectedBodyRegex = "ready"; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = serviceDir; mode = "0700"; }];
    };

    services.${serviceName} = {
      enable = true;
      settings = {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = tempoHttpApiPort;
          grpc_listen_port = 9097;
          log_level = "warn";
        };

        distributor.receivers.otlp.protocols = {
          grpc = {
            endpoint = "127.0.0.1:${toString tempoOtlpGrpcPort}";
            max_recv_msg_size_mib = 20;
          };
          http = {
            endpoint = "0.0.0.0:${toString servicePort}";
          };
        };

        storage.trace = {
          backend = "local";
          local.path = "${serviceDir}/blocks";
          wal.path = "${serviceDir}/wal";
        };

        compactor.compaction = {
          block_retention = "168h";
        };

        metrics_generator = {
          registry.external_labels.source = "tempo";
          processor.local_blocks = {
            filter_server_spans = false;
            flush_to_storage = true;
          };
          storage = {
            path = "${serviceDir}/generator/wal";
            remote_write = [{
              url = "https://${globals.services.mimir.domain}/api/v1/push";
              send_exemplars = true;
            }];
          };
          traces_storage.path = "${serviceDir}/generator/traces";
        };

        overrides.defaults.metrics_generator = {
          processors = [ "service-graphs" "span-metrics" "local-blocks" ];
        };

        usage_report.reporting_enabled = false;
      };
    };

    systemd.services.tempo = {
      serviceConfig.RestartSec = lib.mkForce "60";
      environment = {
        OTEL_TRACES_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
        OTEL_SERVICE_NAME = "tempo-${config.node.name}";
        OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
        OTEL_TRACES_SAMPLER_ARG = "0.01";
      };
    };

    nodes =
      let
        ingestUpstream = "${serviceName}-ingest";
        queryUpstream = "${serviceName}-query";
        genNginx = addr: extraConfig: {
          upstreams = {
            ${ingestUpstream}.servers."${addr}:${toString servicePort}" = { };
            ${queryUpstream}.servers."${addr}:${toString tempoHttpApiPort}" = { };
          };
          virtualHosts.${serviceDomain} = {
            useACMEHost = globals.domains.main;
            forceSSL = true;
            acmeRoot = null;
            locations = {
              "/v1/" = {
                proxyPass = "http://${ingestUpstream}";
                extraConfig = ''
                  client_max_body_size 0;
                '';
              };
              "/" = {
                proxyPass = "http://${queryUpstream}";
                extraConfig = ''
                  client_max_body_size 0;
                '';
              };
            };
            inherit extraConfig;
          };
        };
      in
      lib.mkMerge [
        {
          ${webProxy}.services.nginx = genNginx serviceAddress wgProxyAccessRules;
          ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
          ${globals.general.monitoringServer}.services.grafana = {
            settings = {
              "tracing.opentelemetry" = {
                custom_attributes = "service.name:grafana-${globals.general.monitoringServer}";
              };
              "tracing.opentelemetry.otlp" = {
                address = "127.0.0.1:${toString otlpGrpcPort}";
                propagation = "w3c";
              };
            };
            provision.datasources.settings.datasources = [{
              name = "Tempo";
              uid = "tempo";
              type = "tempo";
              access = "proxy";
              url = confLib.mkAlloyPushUrl {
                host = globals.general.monitoringServer;
                domain = serviceDomain;
                port = tempoHttpApiPort;
                path = "";
              };
              jsonData = {
                nodeGraph.enabled = true;
                search.hide = false;
              } // lib.optionalAttrs ((globals.services.loki.extraConfig.host or null) == globals.general.monitoringServer) {
                tracesToLogsV2 = {
                  datasourceUid = "loki";
                  filterByTraceID = true;
                  filterBySpanID = false;
                };
              } // lib.optionalAttrs ((globals.services.mimir.extraConfig.host or null) == globals.general.monitoringServer) {
                serviceMap.datasourceUid = "mimir";
              } // lib.optionalAttrs ((globals.services.pyroscope.extraConfig.host or null) == globals.general.monitoringServer) {
                tracesToProfiles = {
                  datasourceUid = "pyroscope";
                  profileTypeId = "process_cpu:cpu:nanoseconds:cpu:nanoseconds";
                  tags = [{ key = "service.name"; value = "service_name"; }];
                };
              };
            }];
          };
        }
        (lib.genAttrs (lib.attrNames globals.services.alloy.extraConfig.clients) (alloyHost: {
          environment.etc."alloy/config.alloy".text = lib.mkAfter ''
            otelcol.receiver.otlp "local_tempo" {
              grpc {
                endpoint              = "127.0.0.1:${toString otlpGrpcPort}"
                max_recv_msg_size     = "20MiB"
              }
              http { endpoint = "127.0.0.1:${toString otlpHttpPort}" }

              output {
                traces = [otelcol.exporter.otlphttp.tempo.input]
              }
            }

            otelcol.exporter.otlphttp "tempo" {
              client {
                endpoint = "${confLib.mkAlloyPushUrl {
                  host = alloyHost;
                  domain = serviceDomain;
                  port = servicePort;
                  path = "";
                }}"
              }
            }

            beyla.ebpf "auto" {
              discovery {
                instrument {
                  open_ports = "*"
                  exports = ["traces"]
                }
              }

              output {
                traces = [otelcol.exporter.otlphttp.tempo.input]
              }
            }
          '';
        }))
      ];
  };
}
