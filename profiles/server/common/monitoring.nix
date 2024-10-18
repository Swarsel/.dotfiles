{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.monitoring {

    sops.secrets = {
      grafanaadminpass = {
        owner = "grafana";
      };
    };
    users.users.grafana = {
      extraGroups = [ "users" ];
    };

    services.grafana = {
      enable = true;
      dataDir = "/Vault/data/grafana";
      settings = {
        security.admin_password = "$__file{/run/secrets/grafanaadminpass}";
        server = {
          http_port = 3000;
          http_addr = "127.0.0.1";
          protocol = "https";
          domain = "status.swarsel.win";
          root_url = "%(protocol)s://%(domain)s:%(http_port)s/grafana/";
        };
      };
    };

    services.prometheus = {
      webExternalUrl = "https://status.swarsel.win/prometheus";
      port = 9090;
      listenAddress = "127.0.0.1";
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
            "/grafana" = {
              proxyPass = "http://localhost:3000/grafana/";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
            "/prometheus" = {
              proxyPass = "http://localhost:9090/prometheus/";
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
