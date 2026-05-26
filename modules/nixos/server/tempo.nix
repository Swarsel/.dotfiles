{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen {
    name = "tempo";
    port = 14318;
    dir = "/var/lib/private/tempo";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules wgProxyAccessRules;

  tempoHttpApiPort = 3200;
  tempoOtlpGrpcPort = 14317;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort tempoHttpApiPort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort tempoHttpApiPort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
        extraConfig.port = servicePort;
      };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString tempoHttpApiPort}/ready";
        expectedBodyRegex = "ready";
        network = "local-${config.node.name}";
      };
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
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
        OTEL_SERVICE_NAME = "tempo-${config.node.name}";
        OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
        OTEL_TRACES_SAMPLER_ARG = "0.01";
      };
    };

    globals.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
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
      {
        ${webProxy}.services.nginx = genNginx serviceAddress wgProxyAccessRules;
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
      };
  };
}
