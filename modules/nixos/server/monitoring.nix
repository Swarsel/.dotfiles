{ self, lib, config, ... }:
let
  serviceDomain = "status.swarsel.win";
  servicePort = 3000;
  serviceUser = "grafana";
  serviceGroup = serviceUser;
  moduleName = "monitoring";
  grafanaUpstream = "grafana";
  prometheusUpstream = "prometheus";
  prometheusPort = 9090;
  prometheusWebRoot = "prometheus";
in
{
  options.swarselsystems.modules.server."${moduleName}" = lib.mkEnableOption "enable ${moduleName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${moduleName}" {

    sops.secrets = {
      grafanaadminpass = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      prometheusadminpass = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      kanidm-grafana-client = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    users = {
      users = {
        nextcloud-exporter = {
          extraGroups = [ "nextcloud" ];
        };

        "${serviceUser}" = {
          extraGroups = [ "users" ];
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort prometheusPort ];

    services = {
      grafana = {
        enable = true;
        dataDir = "/Vault/data/grafana";
        provision = {
          enable = true;
          datasources.settings = {
            datasources = [
              {
                name = "prometheus";
                type = "prometheus";
                url = "https://${serviceDomain}/prometheus";
                editable = false;
                access = "proxy";
                basicAuth = true;
                basicAuthUser = "admin";
                jsonData = {
                  httpMethod = "POST";
                  manageAlerts = true;
                  prometheusType = "Prometheus";
                  prometheusVersion = "> 2.50.x";
                  cacheLevel = "High";
                  disableRecordingRules = false;
                  incrementalQueryOverlapWindow = "10m";
                };
                secureJsonData = {
                  basicAuthPassword = "$__file{/run/secrets/prometheusadminpass}";
                };
              }
            ];
          };
        };

        settings = {
          analytics.reporting_enabled = false;
          users.allow_sign_up = false;
          security = {
            admin_password = "$__file{/run/secrets/grafanaadminpass}";
            cookie_secure = true;
            disable_gravatar = true;
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
            #auto_login = true;
            client_id = "grafana";
            client_secret = "$__file{${config.sops.secrets.kanidm-grafana-client.path}}";
            scopes = "openid email profile";
            login_attribute_path = "preferred_username";
            auth_url = "https://sso.swarsel.win/ui/oauth2";
            token_url = "https://sso.swarsel.win/oauth2/token";
            api_url = "https://sso.swarsel.win/oauth2/openid/grafana/userinfo";
            use_pkce = true;
            use_refresh_token = true;
            # Allow mapping oauth2 roles to server admin
            allow_assign_grafana_admin = true;
            role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
          };
        };
      };

      prometheus = {
        enable = true;
        webExternalUrl = "https://status.swarsel.win/${prometheusWebRoot}";
        port = prometheusPort;
        listenAddress = "0.0.0.0";
        globalConfig = {
          scrape_interval = "10s";
        };
        webConfigFile = self + /programs/server/prometheus/web.config;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            }];
          }
          {
            job_name = "zfs";
            static_configs = [{
              targets = [ "localhost:${toString config.services.prometheus.exporters.zfs.port}" ];
            }];
          }
          {
            job_name = "nginx";
            static_configs = [{
              targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
            }];
          }
          {
            job_name = "nextcloud";
            static_configs = [{
              targets = [ "localhost:${toString config.services.prometheus.exporters.nextcloud.port}" ];
            }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            port = 9000;
            enabledCollectors = [ "systemd" ];
            extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
          };
          zfs = {
            enable = true;
            port = 9134;
            pools = [
              "Vault"
            ];
          };
          restic = {
            enable = false;
            port = 9753;
          };
          nginx = {
            enable = true;
            port = 9113;
            sslVerify = false;
            scrapeUri = "http://localhost/nginx_status";
          };
          nextcloud = lib.mkIf config.swarselsystems.modules.server.nextcloud {
            enable = true;
            port = 9205;
            url = "https://stash.swarsel.win/ocs/v2.php/apps/serverinfo/api/v1/info";
            username = "admin";
            passwordFile = config.sops.secrets.nextcloudadminpass.path;
          };
        };
      };
    };


    nodes.moonside.services.nginx = {
      upstreams = {
        "${grafanaUpstream}" = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
        "${prometheusUpstream}" = {
          servers = {
            "192.168.1.2:${builtins.toString prometheusPort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${grafanaUpstream}";
              proxyWebsockets = true;
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
            "/${prometheusWebRoot}" = {
              proxyPass = "http://${prometheusUpstream}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };
}
