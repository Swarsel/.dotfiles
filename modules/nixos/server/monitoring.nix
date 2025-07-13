{ self, lib, config, globals, ... }:
let
  servicePort = 3000;
  serviceUser = "grafana";
  serviceGroup = serviceUser;
  serviceName = "grafana";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  prometheusPort = 9090;
  prometheusUser = "prometheus";
  prometheusGroup = prometheusUser;
  grafanaUpstream = "grafana";
  prometheusUpstream = "prometheus";
  prometheusWebRoot = "prometheus";
  kanidmDomain = globals.services.kanidm.domain;

  inherit (config.swarselsystems) sopsFile;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    sops = {
      secrets = {
        grafana-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        prometheus-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        kanidm-grafana-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        prometheus-admin-hash = { sopsFile = self + /secrets/winters/secrets2.yaml; owner = prometheusUser; group = prometheusGroup; mode = "0440"; };

      };
      templates = {
        "web-config" = {
          content = ''
            basic_auth_users:
              admin: ${config.sops.placeholder.prometheus-admin-hash}
          '';
          owner = prometheusUser;
          group = prometheusGroup;
          mode = "0440";
        };
      };
    };

    users = {
      users = {
        nextcloud-exporter = {
          extraGroups = [ "nextcloud" ];
        };

        ${serviceUser} = {
          extraGroups = [ "users" ];
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort prometheusPort ];

    topology.self.services.prometheus.info = "https://${serviceDomain}/${prometheusWebRoot}";
    globals.services.${serviceName}.domain = serviceDomain;

    services = {
      ${serviceName} = {
        enable = true;
        dataDir = "/Vault/data/${serviceName}";
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
                  basicAuthPassword = "$__file{/run/secrets/prometheus-admin-pw}";
                };
              }
            ];
          };
        };

        settings = {
          analytics.reporting_enabled = false;
          users.allow_sign_up = false;
          security = {
            admin_password = "$__file{/run/secrets/grafana-admin-pw}";
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
            auth_url = "https://${kanidmDomain}/ui/oauth2";
            token_url = "https://${kanidmDomain}/oauth2/token";
            api_url = "https://${kanidmDomain}/oauth2/openid/grafana/userinfo";
            use_pkce = true;
            use_refresh_token = true;
            # Allow mapping oauth2 roles to server admin
            allow_assign_grafana_admin = true;
            role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
          };
        };
      };

      prometheus =
        let
          nextcloudUser = config.repo.secrets.local.nextcloud.adminuser;
        in
        {
          enable = true;
          webExternalUrl = "https://${serviceDomain}/${prometheusWebRoot}";
          port = prometheusPort;
          listenAddress = "0.0.0.0";
          globalConfig = {
            scrape_interval = "10s";
          };
          webConfigFile = config.sops.templates.web-config.path;
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
              url = "https://${serviceDomain}/ocs/v2.php/apps/serverinfo/api/v1/info";
              username = nextcloudUser;
              passwordFile = config.sops.secrets.nextcloud-admin-pw.path;
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
