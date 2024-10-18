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
            prometheus = {
            name = "prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            editable = true;
            access = "proxy";
            jsonData = {
              httpMethod = "POST";
              manageAlerts = true;
              prometheusType = "Prometheus";
              prometheusVersion = "2.51.0";
              cacheLevel = "High";
              disableRecordingRules = false;
              incrementalQueryOverlapWindow = "10m";
              basicAuth = true;
              basicAuthUser = "admin";
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
      webConfigFile = ../../../programs/server/prometheus/web.config;
      exporters = {
        zfs = {
          enable = true;
          port = 9134;
          pools = [
            "Vault"
          ];
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
