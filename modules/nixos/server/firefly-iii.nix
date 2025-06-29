{ self, lib, config, ... }:
let
  cfg = config.services.firefly-iii;
  fireflyDomain = "stonks.swarsel.win";
  fireflyUser = "firefly-iii";
  serviceName = "firefly";
in
{
  options.swarselsystems.modules.server.firefly = lib.mkEnableOption "enable firefly-iii on server";
  config = lib.mkIf config.swarselsystems.modules.server.firefly {

    users.users.firefly-iii = {
      group = "nginx";
      isSystemUser = true;
    };

    sops = {
      secrets = {
        "firefly-iii-app-key" = { owner = fireflyUser; group = "nginx"; mode = "0440"; };
      };
    };

    topology.self.services.firefly-iii = {
      name = "Firefly-III";
      info = "https://${fireflyDomain}";
      icon = "${self}/topology/images/firefly-iii.png";
    };

    services = {
      firefly-iii = {
        enable = true;
        user = fireflyUser;
        group = if cfg.enableNginx then "nginx" else fireflyUser;
        dataDir = "/Vault/data/firefly-iii";
        settings = {
          TZ = config.repo.secrets.common.location.timezone;
          APP_URL = "https://${fireflyDomain}";
          APP_KEY_FILE = config.sops.secrets.firefly-iii-app-key.path;
          APP_ENV = "local";
          DB_CONNECTION = "sqlite";
          TRUSTED_PROXIES = "**";
          # turning these on breaks api access using the waterfly app
          # AUTHENTICATION_GUARD = "remote_user_guard";
          # AUTHENTICATION_GUARD_HEADER = "X-User";
          # AUTHENTICATION_GUARD_EMAIL = "X-Email";
        };
        enableNginx = true;
        virtualHost = fireflyDomain;
      };

      nginx = {
        virtualHosts = {
          "${fireflyDomain}" = {
            locations = {
              "/api" = {
                setOauth2Headers = false;
                extraConfig = ''
                  index index.php;
                  try_files $uri $uri/ /index.php?$query_string;
                  add_header Access-Control-Allow-Methods 'GET, POST, HEAD, OPTIONS';
                '';
              };
            };
          };
        };
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:80" = { };
          };
        };
      };
      virtualHosts = {
        "${fireflyDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = true;
          oauth2.allowedGroups = [ "firefly_access" ];
          # main config is automatically added by nixos firefly config.
          # hence, only provide certificate
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
            };
            "/api" = {
              proxyPass = "http://${serviceName}";
              setOauth2Headers = false;
              bypassAuth = true;
            };
          };
        };
      };
    };
  };
}
