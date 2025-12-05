{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "firefly-iii"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  nginxGroup = "nginx";

  inherit (config.swarselsystems) sopsFile;
  cfg = config.services.firefly-iii;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

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
        "firefly-iii-app-key" = { inherit sopsFile; owner = serviceUser; group = if cfg.enableNginx then nginxGroup else serviceGroup; mode = "0440"; };
      };
    };

    topology.self.services.${serviceName} = {
      name = "Firefly-III";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

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

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          useACMEHost = globals.domains.main;

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
