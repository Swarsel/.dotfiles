{
  flake.modules.nixos.loki =
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
          dir = "/var/lib/loki";
          name = "loki";
          port = 3100;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
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
            expectedBodyRegex = "ready";
            path = "/ready";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        users.persistentIds.loki = confLib.mkIds 948;
        services.${serviceName} = {
          enable = true;
          configuration = {
            analytics.reporting_enabled = false;
            auth_enabled = false;
            common = {
              instance_addr = "127.0.0.1";
              path_prefix = serviceDir;
              replication_factor = 1;
              ring.kvstore.store = "inmemory";
              storage.filesystem = {
                chunks_directory = "${serviceDir}/chunks";
                rules_directory = "${serviceDir}/rules";
              };
            };
            compactor = {
              compactor_ring.kvstore.store = "inmemory";
              retention_enabled = false;
              working_directory = "${serviceDir}/compactor";
            };
            ingester = {
              chunk_idle_period = "5m";
              chunk_retain_period = "30s";
            };
            limits_config = {
              allow_structured_metadata = true;
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
            };
            schema_config.configs = [
              {
                from = "2026-01-01";
                index = {
                  period = "24h";
                  prefix = "index_";
                };
                object_store = "filesystem";
                schema = "v13";
                store = "tsdb";
              }
            ];
            server = {
              grpc_listen_port = 9094;
              http_listen_address = "0.0.0.0";
              http_listen_port = servicePort;
              log_level = "warn";
            };
          };
          dataDir = serviceDir;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        networking.firewall.allowedTCPPorts = [ servicePort ];
        systemd.services.loki = {
          environment = {
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString otlpGrpcPort}";
            OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
            OTEL_SERVICE_NAME = "loki-${config.node.name}";
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
            ${globals.general.monitoringServer}.services.grafana.provision.datasources.settings.datasources = [
              {
                access = "proxy";
                name = "Loki";
                type = "loki";
                uid = "loki";
                url = confLib.mkAlloyPushUrl {
                  domain = serviceDomain;
                  host = globals.general.monitoringServer;
                  path = "";
                  port = servicePort;
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
                      domain = serviceDomain;
                      host = alloyHost;
                      path = "/loki/api/v1/push";
                      port = servicePort;
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
