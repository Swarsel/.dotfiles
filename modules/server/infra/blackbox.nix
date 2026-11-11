{
  flake.modules.nixos.blackbox =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "blackbox";
          port = 9115;
        })
        serviceName
        servicePort
        ;

      hostNetworks = globals.monitoring.hostNetworks.${config.node.name} or [ ];
      defaultProbeFor = "3m";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.prometheus";
          name = "blackbox-exporter";
        };
        globals.monitoring.tcp = lib.mkIf config.services.openssh.enable (
          confLib.mkTcpMonitoring {
            expectedRegex = "^SSH-2.0";
            serviceName = "ssh-${config.node.name}";
            servicePort = lib.head config.services.openssh.ports;
          }
        );
        services.prometheus.exporters.blackbox = {
          enable = true;
          configFile = pkgs.writeText "blackbox.yml" (
            builtins.toJSON {
              modules = {
                icmp = {
                  icmp.preferred_ip_protocol = "ip4";
                  prober = "icmp";
                  timeout = "5s";
                };
              }
              // lib.concatMapAttrs (name: cfg: {
                "http_${name}" = {
                  http = {
                    follow_redirects = true;
                    method = "GET";
                    preferred_ip_protocol = "ip4";
                    tls_config.insecure_skip_verify = true;
                    valid_status_codes = [ cfg.expectedStatus ];
                  }
                  // lib.optionalAttrs (cfg.expectedBodyRegex != null) {
                    fail_if_body_not_matches_regexp = [ cfg.expectedBodyRegex ];
                  }
                  // lib.optionalAttrs (cfg.failIfBodyMatchesRegex != null) {
                    fail_if_body_matches_regexp = [ cfg.failIfBodyMatchesRegex ];
                  }
                  // lib.optionalAttrs (cfg.hostHeader != null) {
                    headers.Host = cfg.hostHeader;
                  };
                  prober = "http";
                  timeout = "10s";
                };
              }) globals.monitoring.http
              // lib.concatMapAttrs (name: cfg: {
                "tcp_${name}" = {
                  prober = "tcp";
                  tcp = {
                    inherit (cfg) tls;
                    preferred_ip_protocol = "ip4";
                    tls_config.insecure_skip_verify = true;
                  }
                  // lib.optionalAttrs (cfg.expectedRegex != null) {
                    query_response = [ { expect = cfg.expectedRegex; } ];
                  };
                  timeout = "10s";
                };
              }) globals.monitoring.tcp
              // lib.concatMapAttrs (name: cfg: {
                "dns_${name}" = {
                  dns = {
                    preferred_ip_protocol = "ip4";
                    query_name = cfg.queryName;
                    query_type = cfg.queryType;
                    valid_rcodes = [ "NOERROR" ];
                    validate_answer_rrs.fail_if_none_matches_regexp = [ ".+" ];
                  };
                  prober = "dns";
                  timeout = "5s";
                };
              }) globals.monitoring.dns
              // lib.concatMapAttrs (name: cfg: {
                "cert_${name}" = {
                  prober = "tcp";
                  tcp = {
                    preferred_ip_protocol = "ip4";
                    tls = true;
                    tls_config = {
                      insecure_skip_verify = true;
                      server_name = cfg.serverName;
                    };
                  };
                  timeout = "10s";
                };
              }) globals.monitoring.cert;
            }
          );
          listenAddress = "127.0.0.1";
          port = servicePort;
        };
        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter (
            lib.concatMapStrings (
              kind:
              let
                targets = lib.mapAttrsToList (name: cfg: {
                  inherit name;
                  __address__ =
                    {
                      http = cfg.url;
                      ping = cfg.host;
                    }
                    .${kind} or cfg.address;
                  __param_module = if kind == "ping" then "icmp" else "${kind}_${name}";
                  probe = kind;
                }) (lib.filterAttrs (_: cfg: builtins.elem cfg.network hostNetworks) globals.monitoring.${kind});
              in
              lib.optionalString (targets != [ ]) ''

                discovery.relabel "blackbox_${kind}" {
                  targets = [
                    ${
                      lib.concatMapStringsSep ",\n" (
                        target:
                        "{${
                          lib.concatStringsSep ", " (
                            lib.mapAttrsToList (key: value: "${builtins.toJSON key} = ${builtins.toJSON value}") target
                          )
                        }}"
                      ) targets
                    },
                  ]

                  rule {
                    source_labels = ["__address__"]
                    target_label  = "__param_target"
                  }
                  rule {
                    source_labels = ["__param_target"]
                    target_label  = "instance"
                  }
                  rule {
                    target_label = "__address__"
                    replacement  = "127.0.0.1:${toString servicePort}"
                  }
                  rule {
                    target_label = "probe_from"
                    replacement  = "${config.node.name}"
                  }
                }

                prometheus.scrape "blackbox_${kind}" {
                  targets      = discovery.relabel.blackbox_${kind}.output
                  metrics_path = "/probe"
                  job_name     = "blackbox_${kind}"
                  forward_to   = [prometheus.remote_write.mimir.receiver]
                }
              ''
            ) confLib.static.probeKinds
          )
        );
        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          [
            {
              folder = "Infrastructure";
              interval = "1m";
              name = "blackbox";
              orgId = 1;
              rules =
                lib.concatMap
                  (
                    kind:
                    let
                      probes = globals.monitoring.${kind};
                    in
                    lib.mapAttrsToList (
                      forDuration: names:
                      let
                        selector = ''probe="${kind}",name=~"${lib.concatStringsSep "|" names}"'';
                        isDefault = forDuration == defaultProbeFor;
                      in
                      confLib.mkGrafanaAlertRule {
                        inherit forDuration;
                        expr = "min by (name) (probe_success{${selector}}) or on(name) (probe_expected{${selector}} * 0)";
                        summary = "Blackbox ${lib.toUpper kind} probe for {{ $labels.name }} has been failing";
                        title = "${lib.toUpper kind} probe failed${
                          lib.optionalString (!isDefault) " (after ${forDuration})"
                        }";
                        uid = "${kind}_probe_failed${lib.optionalString (!isDefault) "_${forDuration}"}";
                      }
                    ) (lib.groupBy (name: lib.defaultTo defaultProbeFor probes.${name}.alertFor) (lib.attrNames probes))
                  )
                  [
                    "dns"
                    "http"
                    "tcp"
                  ]
                ++ [
                  (confLib.mkGrafanaAlertRule {
                    expr = ''min by (name) ((probe_ssl_earliest_cert_expiry{probe="cert"} - time()) / 86400) or on(name) (max by (name) (probe_expected{probe="cert"}) * 0)'';
                    severity = "warning";
                    summary = "Certificate served by {{ $labels.name }} expires in {{ $values.A.Value | printf \"%.0f\" }} days or could not be fetched";
                    threshold = 14;
                    title = "Certificate expiring";
                    uid = "cert_expiring";
                  })
                ];
            }
          ];
      };
    };
}
