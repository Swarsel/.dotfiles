{ self, lib, config, ... }:
let
  grafanaDomain = "status.swarsel.win";
in
{
  options.swarselsystems.modules.server.monitoring = lib.mkEnableOption "enable monitoring on server";
  config = lib.mkIf config.swarselsystems.modules.server.monitoring {

    sops.secrets = {
      grafanaadminpass = {
        owner = "grafana";
      };
      prometheusadminpass = {
        owner = "grafana";
      };
      kanidm-grafana-client = {
        owner = "grafana";
        group = "grafana";
        mode = "440";
      };
    };

    users = {
      users = {
        nextcloud-exporter = {
          extraGroups = [ "nextcloud" ];
        };

        grafana = {
          extraGroups = [ "users" ];
        };
      };
    };

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
                url = "https://${grafanaDomain}/prometheus";
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
          security.admin_password = "$__file{/run/secrets/grafanaadminpass}";
          server = {
            domain = grafanaDomain;
            root_url = "https://${grafanaDomain}";
            http_port = 3000;
            http_addr = "0.0.0.0";
            protocol = "http";
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
        webExternalUrl = "https://status.swarsel.win/prometheus";
        port = 9090;
        listenAddress = "127.0.0.1";
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


      nginx = {
        virtualHosts = {
          "status.swarsel.win" = {
            enableACME = true;
            forceSSL = true;
            acmeRoot = null;
            locations = {
              "/" = {
                proxyPass = "http://localhost:3000";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 0;
                '';
              };
              "/prometheus" = {
                proxyPass = "http://localhost:9090";
                extraConfig = ''
                  client_max_body_size 0;
                '';
              };
            };
          };
        };
      };
    };
  };

}
