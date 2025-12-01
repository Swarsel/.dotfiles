{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "attic"; port = 8091; }) serviceName serviceDir servicePort serviceAddress serviceDomain serviceProxy proxyAddress4 proxyAddress6;
  inherit (config.swarselsystems) mainUser isPublic sopsFile;
  serviceDB = "atticd";
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    sops = lib.mkIf (!isPublic) {
      secrets = {
        attic-server-token = { inherit sopsFile; };
        attic-garage-access-key = { inherit sopsFile; };
        attic-garage-secret-key = { inherit sopsFile; };
      };
      templates = {
        "attic.env" = {
          content = ''
            ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder.attic-server-token}
            AWS_ACCESS_KEY_ID=${config.sops.placeholder.attic-garage-access-key}
            AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.attic-garage-secret-key}
          '';
        };
      };
    };

    services.atticd = {
      enable = true;
      environmentFile = config.sops.templates."attic.env".path;
      settings = {
        listen = "[::]:${builtins.toString servicePort}";
        api-endpoint = "https://${serviceDomain}/";
        allowed-hosts = [
          serviceDomain
        ];
        require-proof-of-possession = false;
        compression = {
          type = "zstd";
          level = 3;
        };
        database.url = "postgresql:///atticd?host=/run/postgresql";

        storage =
          if config.swarselmodules.server.garage then {
            type = "s3";
            region = mainUser;
            bucket = serviceName;
            # attic must be patched to never serve pre-signed s3 urls directly
            # otherwise it will redirect clients to this localhost endpoint
            endpoint = "http://127.0.0.1:3900";
          } else {
            type = "local";
            path = serviceDir;
            # attic must be patched to never serve pre-signed s3 urls directly
            # otherwise it will redirect clients to this localhost endpoint
          };

        garbage-collection = {
          interval = "1 day";
          default-retention-period = "3 months";
        };

        chunking = {
          nar-size-threshold = if config.swarselmodules.server.garage then 0 else 64 * 1024; # 64 KiB

          min-size = 16 * 1024; # 16 KiB
          avg-size = 64 * 1024; # 64 KiB
          max-size = 256 * 1024; # 256 KiBize = 262144;
        };
      };
    };

    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      ensureDatabases = [ serviceDB ];
      ensureUsers = [
        {
          name = serviceDB;
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.atticd = lib.mkIf config.swarselmodules.server.garage {
      requires = [ "garage.service" ];
      after = [ "garage.service" ];
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
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
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
