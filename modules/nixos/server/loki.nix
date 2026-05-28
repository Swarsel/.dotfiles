{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen {
    name = "loki";
    port = 3100;
    dir = "/var/lib/loki";
  }) servicePort serviceName serviceUser serviceGroup serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules wgProxyAccessRules;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    users.persistentIds.loki = confLib.mkIds 948;

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig.port = servicePort; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/ready"; expectedBodyRegex = "ready"; };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = serviceDir; user = serviceUser; group = serviceGroup; }];
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

        schema_config.configs = [{
          from = "2026-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];

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
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
        OTEL_SERVICE_NAME = "loki-${config.node.name}";
      };
    };

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
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
    };
  };
}
