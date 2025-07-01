{ self, lib, config, ... }:
let
  servicePort = 80;
  serviceUser = "firefly-iii";
  serviceGroup = serviceUser;
  serviceName = "firefly-iii";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  nginxGroup = "nginx";

  cfg = config.services.firefly-iii;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    users = {
      groups.${serviceGroup} = { };
      users.${serviceUser} = {
        group = lib.mkForce serviceGroup;
        extraGroups = lib.mkIf cfg.enableNginx [ nginxGroup ];
        isSystemUser = true;
      };
    };

    sops = {
      secrets = {
        "firefly-iii-app-key" = { owner = serviceUser; group = if cfg.enableNginx then nginxGroup else serviceGroup; mode = "0440"; };
      };
    };

    topology.self.services.${serviceName} = {
      name = "Firefly-III";
      info = "https://${serviceDomain}";
      icon = "${self}/topology/images/${serviceName}.png";
    };
    globals.services.${serviceName}.domain = serviceDomain;

    services = {
      ${serviceName} = {
        enable = true;
        user = serviceUser;
        group = if cfg.enableNginx then nginxGroup else serviceGroup;
        dataDir = "/Vault/data/${serviceName}";
        settings = {
          TZ = config.repo.secrets.common.location.timezone;
          APP_URL = "https://${serviceDomain}";
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
        virtualHost = serviceDomain;
      };

      nginx = {
        virtualHosts = {
          "${serviceDomain}" = {
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
        ${serviceName} = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
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
