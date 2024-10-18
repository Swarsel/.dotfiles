{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.monitoring {

    sops.secrets = {
      grafanaadminpass = {
        owner = "grafana";
      };
      prometheusadminpass = {
        owner = "grafana";
      };
    };
    users.users.grafana = {
      extraGroups = [ "users" ];
    };

    services.grafana = {
      enable = true;
      dataDir = "/Vault/data/grafana";
      provision = {
        enable = true;
        datasources.settings = {
          datasources = [
            {
              name = "prometheus";
              type = "prometheus";
              url = "https://status.swarsel.win/prometheus";
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
          http_port = 3000;
          http_addr = "127.0.0.1";
          protocol = "http";
          domain = "status.swarsel.win";
        };
      };
    };

    services.prometheus = {
      enable = true;
      webExternalUrl = "https://status.swarsel.win/prometheus";
      port = 9090;
      listenAddress = "127.0.0.1";
      globalConfig = {
        scrape_interval = "10s";
      };
      webConfigFile = ../../../programs/server/prometheus/web.config;
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
      };
    };
  };

  services.nginx = {
    virtualHosts = {
      "status.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "/" = {
            proxyPass = "http://localhost:3000";
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

}
