{
  flake.modules.nixos.loki =
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
          name = "loki";
          port = 3100;
          dir = "/var/lib/loki";
        })
        servicePort
        serviceName
        serviceUser
        serviceGroup
        serviceDir
        serviceDomain
        serviceAddress
        proxyAddress4
        proxyAddress6
        ;
      inherit (confLib.static)
        isHome
        webProxy
        homeWebProxy
        homeServiceAddress
        nginxAccessRules
        wgProxyAccessRules
        ;
      inherit (globals.services.alloy.extraConfig) otlpGrpcPort;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        users.persistentIds.loki = confLib.mkIds 948;

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal {
            inherit
              serviceName
              serviceDomain
              proxyAddress4
              proxyAddress6
              isHome
              serviceAddress
              homeServiceAddress
              ;
            extra.extraConfig = {
              port = servicePort;
              host = config.node.name;
            };
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            path = "/ready";
            expectedBodyRegex = "ready";
          };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        networking.firewall.allowedTCPPorts = [ servicePort ];

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              user = serviceUser;
              group = serviceGroup;
            }
          ];
        };

        services.${serviceName} = {
          enable = true;
          dataDir = serviceDir;
          configuration = {
            analytics.reporting_enabled = false;
            auth_enabled = false;

            server = {
              http_listen_address = "0.0.0.0";
              http_listen_port = servicePort;
              grpc_listen_port = 9094;
              log_level = "warn";
            };

            common = {
              path_prefix = serviceDir;
              storage.filesystem = {
                chunks_directory = "${serviceDir}/chunks";
                rules_directory = "${serviceDir}/rules";
              };
              replication_factor = 1;
              ring.kvstore.store = "inmemory";
              instance_addr = "127.0.0.1";
            };

            schema_config.configs = [
              {
                from = "2026-01-01";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];

            ingester = {
              chunk_idle_period = "5m";
              chunk_retain_period = "30s";
            };

            limits_config = {
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
              allow_structured_metadata = true;
            };

            compactor = {
              working_directory = "${serviceDir}/compactor";
              compactor_ring.kvstore.store = "inmemory";
              retention_enabled = false;
            };
          };
        };

        systemd.services.loki = {
          serviceConfig.RestartSec = lib.mkForce "60";
          environment = {
            OTEL_TRACES_EXPORTER = "otlp";
            OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
            OTEL_SERVICE_NAME = "loki-${config.node.name}";
          };
        };

        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                servicePort
                serviceDomain
                serviceName
                ;
              maxBody = 0;
              extraConfig = wgProxyAccessRules;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit servicePort serviceDomain serviceName;
                serviceAddress = homeServiceAddress;
                maxBody = 0;
                extraConfig = nginxAccessRules;
              }
            );
          }
          {
            ${globals.general.monitoringServer}.services.grafana.provision.datasources.settings.datasources = [
              {
                name = "Loki";
                uid = "loki";
                type = "loki";
                access = "proxy";
                url = confLib.mkAlloyPushUrl {
                  host = globals.general.monitoringServer;
                  domain = serviceDomain;
                  port = servicePort;
                  path = "";
                };
              }
            ];
          }
          (lib.genAttrs (lib.attrNames globals.services.alloy.extraConfig.clients) (alloyHost: {
            environment.etc."alloy/config.alloy".text = lib.mkAfter ''
              loki.relabel "journal" {
                forward_to = []
                rule {
                  source_labels = ["__journal__systemd_unit"]
                  target_label  = "unit"
                }
                rule {
                  source_labels = ["__journal_priority_keyword"]
                  target_label  = "level"
                }
              }

              loki.source.journal "journal" {
                max_age       = "12h"
                relabel_rules = loki.relabel.journal.rules
                forward_to    = [loki.write.central.receiver]
                labels        = {
                  host = "${alloyHost}",
                  job  = "systemd-journal",
                }
              }

              loki.write "central" {
                endpoint {
                  url = "${
                    confLib.mkAlloyPushUrl {
                      host = alloyHost;
                      domain = serviceDomain;
                      port = servicePort;
                      path = "/loki/api/v1/push";
                    }
                  }"
                }
              }
            '';
          }))
        ];
      };
    }

  ;
}
