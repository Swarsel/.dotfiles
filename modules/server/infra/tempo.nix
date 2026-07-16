{
  flake.modules.nixos.tempo =
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
          dir = "/var/lib/private/tempo";
          name = "tempo";
          port = 14318;
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
      inherit (globals.services.alloy.extraConfig) otlpGrpcPort otlpHttpPort;

      tempoHttpApiPort = 3200;
      tempoOtlpGrpcPort = 14317;
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
            inherit serviceName;
            expectedBodyRegex = "ready";
            path = "/ready";
            servicePort = tempoHttpApiPort;
          };
          networks = confLib.mkDualFirewallRules {
            tcpPorts = [
              servicePort
              tempoHttpApiPort
            ];
          };
        };
        services.${serviceName} = {
          enable = true;
          settings = {
            backend_scheduler = {
              local_work_path = "${serviceDir}/scheduler";
              provider.compaction.compaction.block_retention = "168h";
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
            live_store = {
              shutdown_marker_dir = "${serviceDir}/live-store/shutdown-marker";
              wal.path = "${serviceDir}/live-store/traces";
            };
            metrics_generator = {
              registry.external_labels.source = "tempo";
              storage = {
                path = "${serviceDir}/generator/wal";
                remote_write = [
                  {
                    send_exemplars = true;
                    url = "https://${globals.services.mimir.domain}/api/v1/push";
                  }
                ];
              };
            };
            overrides.defaults.metrics_generator = {
              processors = [
                "service-graphs"
                "span-metrics"
              ];
            };
            server = {
              grpc_listen_port = 9097;
              http_listen_address = "0.0.0.0";
              http_listen_port = tempoHttpApiPort;
              log_level = "warn";
            };
            storage.trace = {
              backend = "local";
              local.path = "${serviceDir}/blocks";
              wal.path = "${serviceDir}/wal";
            };
            usage_report.reporting_enabled = false;
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
        systemd.services.tempo = {
          environment = {
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
            OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
            OTEL_SERVICE_NAME = "tempo-${config.node.name}";
            OTEL_TRACES_EXPORTER = "otlp";
            OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
            OTEL_TRACES_SAMPLER_ARG = "0.01";
          };
          serviceConfig.RestartSec = lib.mkForce "60";
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
                inherit extraConfig;
                acmeRoot = null;
                forceSSL = true;
                locations = {
                  "/" = {
                    extraConfig = ''
                      client_max_body_size 0;
                    '';
                    proxyPass = "http://${queryUpstream}";
                  };
                  "/v1/" = {
                    extraConfig = ''
                      client_max_body_size 0;
                    '';
                    proxyPass = "http://${ingestUpstream}";
                  };
                };
                useACMEHost = globals.domains.main;
              };
            };
          in
          lib.mkMerge [
            {
              ${webProxy}.services.nginx = genNginx serviceAddress wgProxyAccessRules;
            }
            {
              ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
            }
            {
              ${globals.general.monitoringServer}.services.grafana = {
                provision.datasources.settings.datasources = [
                  {
                    access = "proxy";
                    jsonData = {
                      nodeGraph.enabled = true;
                      search.hide = false;
                    }
                    //
                      lib.optionalAttrs
                        ((globals.services.loki.extraConfig.host or null) == globals.general.monitoringServer)
                        {
                          tracesToLogsV2 = {
                            datasourceUid = "loki";
                            filterBySpanID = false;
                            filterByTraceID = true;
                          };
                        }
                    //
                      lib.optionalAttrs
                        ((globals.services.mimir.extraConfig.host or null) == globals.general.monitoringServer)
                        {
                          serviceMap.datasourceUid = "mimir";
                        }
                    //
                      lib.optionalAttrs
                        ((globals.services.pyroscope.extraConfig.host or null) == globals.general.monitoringServer)
                        {
                          tracesToProfiles = {
                            datasourceUid = "pyroscope";
                            profileTypeId = "process_cpu:cpu:nanoseconds:cpu:nanoseconds";
                            tags = [
                              {
                                key = "service.name";
                                value = "service_name";
                              }
                            ];
                          };
                        };
                    name = "Tempo";
                    type = "tempo";
                    uid = "tempo";
                    url = confLib.mkAlloyPushUrl {
                      domain = serviceDomain;
                      host = globals.general.monitoringServer;
                      path = "";
                      port = tempoHttpApiPort;
                    };
                  }
                ];
                settings = {
                  "tracing.opentelemetry" = {
                    custom_attributes = "service.name:grafana-${globals.general.monitoringServer}";
                  };
                  "tracing.opentelemetry.otlp" = {
                    address = "127.0.0.1:${toString otlpGrpcPort}";
                    propagation = "w3c";
                  };
                };
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
                    endpoint = "${
                      confLib.mkAlloyPushUrl {
                        domain = serviceDomain;
                        host = alloyHost;
                        path = "";
                        port = servicePort;
                      }
                    }"
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

  ;
}
