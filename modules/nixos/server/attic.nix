{ lib, config, pkgs, globals, dns, confLib, ... }:
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

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services.atticd = {
      enable = true;
      # NOTE: remove once https://github.com/zhaofengli/attic/pull/268 is merged
      package = pkgs.attic-server.overrideAttrs
        (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            (pkgs.writeText "remove-s3-checksums.patch" ''
              diff --git a/server/src/storage/s3.rs b/server/src/storage/s3.rs
              index 1d5719f3..036f3263 100644
              --- a/server/src/storage/s3.rs
              +++ b/server/src/storage/s3.rs
              @@ -278,10 +278,6 @@ impl StorageBackend for S3Backend {
                               CompletedPart::builder()
                                   .set_e_tag(part.e_tag().map(str::to_string))
                                   .set_part_number(Some(part_number as i32))
              -                    .set_checksum_crc32(part.checksum_crc32().map(str::to_string))
              -                    .set_checksum_crc32_c(part.checksum_crc32_c().map(str::to_string))
              -                    .set_checksum_sha1(part.checksum_sha1().map(str::to_string))
              -                    .set_checksum_sha256(part.checksum_sha256().map(str::to_string))
                                   .build()
                           })
                           .collect::<Vec<_>>();
            '')
          ];
        });
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
            endpoint = "http://127.0.0.1:3900"; # garage port
          } else {
            type = "local";
            path = serviceDir;
          };

        garbage-collection = {
          interval = "1 day";
          default-retention-period = "3 months";
        };

        chunking = {
          nar-size-threshold = if config.swarselmodules.server.garage then 0 else 64 * 1024; # garage using s3

          min-size = 16 * 1024;
          avg-size = 64 * 1024;
          max-size = 256 * 1024;
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
          useACMEHost = globals.domains.main;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
                client_body_timeout        600s;
                proxy_connect_timeout      600s;
                proxy_send_timeout         600s;
                proxy_read_timeout         600s;
                proxy_request_buffering    off;
              '';
            };
          };
        };
      };
    };

  };
}
