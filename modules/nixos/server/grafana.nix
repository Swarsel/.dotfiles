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
            };
          };

        dashboards.settings.providers = [{
          name = "default";
          options.path = self + "/files/grafana";
        }];
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
