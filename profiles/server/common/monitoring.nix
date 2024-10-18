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
              proxyPass = "http://localhost:3000/";
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
