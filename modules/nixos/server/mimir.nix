{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen {
    name = "mimir";
    port = 9009;
    dir = "/var/lib/private/mimir";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules wgProxyAccessRules;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig.port = servicePort; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/services";
        expectedBodyRegex = "Running";
        failIfBodyMatchesRegex = "(Starting|Stopping|Failed|Terminated|New|Stuck)";
        network = "local-${config.node.name}";
      };
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
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
        OTEL_SERVICE_NAME = "mimir-${config.node.name}";
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
