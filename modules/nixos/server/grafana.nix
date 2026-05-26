{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen {
    name = "grafana";
    port = 3000;
    dir = "/var/lib/grafana";
  }) servicePort serviceName serviceUser serviceGroup serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  inherit (config.swarselsystems) sopsFile;

  kanidmDomain = globals.services.kanidm.domain;
  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    sops.secrets = {
      grafana-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      kanidm-grafana = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      grafana-gotify-token = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      grafana-smtp-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    users = {
      persistentIds.grafana = confLib.mkIds 974;
      users.${serviceUser}.extraGroups = [ "users" ];
    };

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
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/api/health";
        expectedBodyRegex = "ok|database";
        network = "local-${config.node.name}";
      };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = serviceDir; user = serviceUser; group = serviceGroup; }
      ];
    };

    services.${serviceName} = {
      enable = true;
      dataDir = serviceDir;
      provision = {
        enable = true;
        datasources.settings.datasources =
          let
            hasMimir = builtins.elem "mimir" config.swarselsystems.enabledServerModules;
            hasLoki = builtins.elem "loki" config.swarselsystems.enabledServerModules;
            hasTempo = builtins.elem "tempo" config.swarselsystems.enabledServerModules;
            hasPyroscope = builtins.elem "pyroscope" config.swarselsystems.enabledServerModules;
            mimirUrl =
              if hasMimir
              then "http://127.0.0.1:${toString globals.services.mimir.extraConfig.port}/prometheus"
              else "https://${globals.services.mimir.domain}/prometheus";
            lokiUrl =
              if hasLoki
              then "http://127.0.0.1:${toString globals.services.loki.extraConfig.port}"
              else "https://${globals.services.loki.domain}";
            tempoUrl =
              if hasTempo
              then "http://127.0.0.1:3200"
              else "https://${globals.services.tempo.domain}";
            pyroscopeUrl =
              if hasPyroscope
              then "http://127.0.0.1:${toString globals.services.pyroscope.extraConfig.port}"
              else "https://${globals.services.pyroscope.domain}";
          in
          lib.optional hasMimir
            {
              name = "Mimir";
              uid = "mimir";
              type = "prometheus";
              access = "proxy";
              url = mimirUrl;
              isDefault = true;
              jsonData = {
                httpMethod = "POST";
                manageAlerts = true;
                prometheusType = "Mimir";
                cacheLevel = "High";
                incrementalQueryOverlapWindow = "10m";
              };
            }
          ++ lib.optional hasLoki {
            name = "Loki";
            uid = "loki";
            type = "loki";
            access = "proxy";
            url = lokiUrl;
          }
          ++ lib.optional hasTempo {
            name = "Tempo";
            uid = "tempo";
            type = "tempo";
            access = "proxy";
            url = tempoUrl;
            jsonData = {
              nodeGraph.enabled = true;
              search.hide = false;
            } // lib.optionalAttrs hasLoki {
              tracesToLogsV2 = {
                datasourceUid = "loki";
                filterByTraceID = true;
                filterBySpanID = false;
              };
            } // lib.optionalAttrs hasMimir {
              serviceMap.datasourceUid = "mimir";
            } // lib.optionalAttrs hasPyroscope {
              tracesToProfiles = {
                datasourceUid = "pyroscope";
                profileTypeId = "process_cpu:cpu:nanoseconds:cpu:nanoseconds";
                tags = [{ key = "service.name"; value = "service_name"; }];
              };
            };
          }
          ++ lib.optional hasPyroscope {
            name = "Pyroscope";
            uid = "pyroscope";
            type = "grafana-pyroscope-datasource";
            access = "proxy";
            url = pyroscopeUrl;
          };

        dashboards.settings.providers = [{
          name = "default";
          options.path = self + "/files/grafana";
        }];

        alerting = {
          contactPoints.settings = {
            apiVersion = 1;
            contactPoints = [{
              orgId = 1;
              name = "default";
              receivers = [
                {
                  uid = "gotify_webhook";
                  type = "webhook";
                  settings = {
                    url = "https://${globals.services.gotify.domain}/message?token=$__file{${config.sops.secrets.grafana-gotify-token.path}}";
                    httpMethod = "POST";
                    title = "{{ template \"default.title\" . }}";
                    message = "{{ template \"default.message\" . }}";
                  };
                }
                {
                  uid = "email_default";
                  type = "email";
                  settings = {
                    addresses = "monitoring@${globals.domains.main}";
                    singleEmail = false;
                  };
                }
              ];
            }];
          };

          policies.settings = {
            apiVersion = 1;
            policies = [{
              orgId = 1;
              receiver = "default";
              group_by = [ "grafana_folder" "alertname" ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            }];
          };

          rules.settings =
            let
              mkRule = { uid, title, expr, op ? "lt", threshold ? 1, forDuration ? "5m", severity ? "critical", summary }:
                {
                  inherit uid title;
                  condition = "C";
                  for = forDuration;
                  noDataState = "NoData";
                  execErrState = "Alerting";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = { from = 600; to = 0; };
                      datasourceUid = "mimir";
                      model = {
                        refId = "A";
                        inherit expr;
                        range = false;
                        instant = true;
                      };
                    }
                    {
                      refId = "C";
                      datasourceUid = "__expr__";
                      model = {
                        refId = "C";
                        type = "threshold";
                        expression = "A";
                        conditions = [{
                          evaluator = { type = op; params = [ threshold ]; };
                        }];
                      };
                    }
                  ];
                  annotations.summary = summary;
                  labels.severity = severity;
                };
            in
            {
              apiVersion = 1;
              groups = [{
                orgId = 1;
                name = "core";
                folder = "Infrastructure";
                interval = "1m";
                rules = [
                  (mkRule {
                    uid = "host_down";
                    title = "Host down";
                    expr = "max by (host) (up) or max by (host) (host_expected * 0)";
                    summary = "{{ $labels.host }} stopped reporting (no `up` series and `host_expected` fallback fired)";
                  })
                  (mkRule {
                    uid = "http_probe_failed";
                    title = "HTTP probe failed";
                    expr = ''min by (name) (probe_success{probe="http"}) or on(name) (probe_expected{probe="http"} * 0)'';
                    forDuration = "3m";
                    summary = "Blackbox HTTP probe for {{ $labels.name }} has been failing";
                  })
                  (mkRule {
                    uid = "disk_filling";
                    title = "Disk above 80% used";
                    expr = ''max by (host, mountpoint) (100 - (node_filesystem_avail_bytes{fstype!~"tmpfs|.*tmpfs|overlay"} / node_filesystem_size_bytes * 100))'';
                    op = "gt";
                    threshold = 80;
                    forDuration = "10m";
                    severity = "warning";
                    summary = "{{ $labels.host }}:{{ $labels.mountpoint }} is more than 80% full";
                  })
                  (mkRule {
                    uid = "zfs_pool_unhealthy";
                    title = "ZFS pool not online";
                    expr = "max by (host, pool) (zfs_pool_health)";
                    op = "gt";
                    threshold = 0;
                    forDuration = "5m";
                    summary = "ZFS pool {{ $labels.host }}:{{ $labels.pool }} is not ONLINE";
                  })
                ];
              }];
            };
        };
      };

      settings = {
        analytics.reporting_enabled = false;
        users.allow_sign_up = false;
        security = {
          disable_initial_admin_creation = true;
          secret_key = "$__file{${config.sops.secrets.grafana-admin-pw.path}}";
          cookie_secure = true;
          disable_gravatar = true;
          hide_version = true;
        };
        server = {
          domain = serviceDomain;
          root_url = "https://${serviceDomain}";
          http_port = servicePort;
          http_addr = "0.0.0.0";
          protocol = "http";
          enforce_domain = true;
          enable_gzip = true;
        };
        smtp = {
          enabled = true;
          host = "${globals.services.mailserver.domain}:587";
          user = "notification@${globals.domains.main}";
          password = "$__file{${config.sops.secrets.grafana-smtp-pw.path}}";
          from_address = "monitoring@${globals.domains.main}";
          from_name = "Monitoring";
          startTLS_policy = "MandatoryStartTLS";
        };
        "tracing.opentelemetry" = {
          custom_attributes = "service.name:grafana-${config.node.name}";
        };
        "tracing.opentelemetry.otlp" = {
          address = "127.0.0.1:${toString globals.services.alloy.extraConfig.otlpGrpcPort}";
          propagation = "w3c";
        };
        "auth.generic_oauth" = {
          enabled = true;
          name = "Kanidm";
          icon = "signin";
          allow_sign_up = true;
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.kanidm-grafana.path}}";
          scopes = "openid email profile";
          login_attribute_path = "preferred_username";
          auth_url = "https://${kanidmDomain}/ui/oauth2";
          token_url = "https://${kanidmDomain}/oauth2/token";
          api_url = "https://${kanidmDomain}/oauth2/openid/grafana/userinfo";
          use_pkce = true;
          use_refresh_token = true;
          allow_assign_grafana_admin = true;
          role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
        };
      };
    };

    systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";

    globals.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    nodes = {
      ${idmServer} = {
        sops.secrets.kanidm-grafana = { sopsFile = kanidmSopsFile; owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        services.kanidm.provision = {
          groups = {
            "grafana.access" = { };
            "grafana.editors" = { };
            "grafana.admins" = { };
            "grafana.server-admins" = { };
          };
          systems.oauth2.grafana = {
            displayName = "Grafana";
            originUrl = "https://${serviceDomain}/login/generic_oauth";
            originLanding = "https://${serviceDomain}/";
            basicSecretFile = config.sops.secrets.kanidm-grafana.path;
            preferShortUsername = true;
            scopeMaps."grafana.access" = [ "openid" "email" "profile" ];
            claimMaps.groups = {
              joinType = "array";
              valuesByGroup = {
                "grafana.editors" = [ "editor" ];
                "grafana.admins" = [ "admin" ];
                "grafana.server-admins" = [ "server_admin" ];
              };
            };
          };
        };
      };
      ${webProxy}.services.nginx = confLib.genNginx {
        inherit serviceAddress servicePort serviceDomain serviceName;
        proxyWebsockets = true;
      };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx {
        inherit servicePort serviceDomain serviceName;
        serviceAddress = homeServiceAddress;
        proxyWebsockets = true;
        extraConfig = nginxAccessRules;
      });
    };
  };
}
