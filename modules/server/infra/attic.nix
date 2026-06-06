{
  flake.modules.nixos.attic =
    { self, lib, config, pkgs, globals, confLib, ... }:
    let
      inherit (confLib.gen { name = "attic"; port = 8091; }) serviceName serviceDir servicePort serviceAddress serviceDomain proxyAddress4 proxyAddress6;
      inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules;
      inherit (config.swarselsystems) mainUser isPublic sopsFile;
      serviceDB = "atticd";
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ "attic" ];

        topology.self.services.${serviceName} = {
          name = lib.swarselsystems.toCapitalized serviceName;
          info = "https://${serviceDomain}";
          icon = "services.not-available";
          # attic does not have a logo
        };

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
          monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; expectedBodyRegex = "Attic Binary Cache"; hostHeader = serviceDomain; };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
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

        # networking.firewall.allowedTCPPorts = [ servicePort ];

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
              if builtins.elem "garage" config.swarselsystems.enabledServerModules then {
                type = "s3";
                region = mainUser;
                bucket = serviceName;
                # attic must be patched to never serve pre-signed s3 urls directly
                # otherwise it will redirect clients to this localhost endpoint
                # endpoint = "http://127.0.0.1:3900"; # garage port
                endpoint = "https://${globals.services."garage-${config.node.name}".domain}";
              } else {
                type = "local";
                path = serviceDir;
              };

            garbage-collection = {
              interval = "1 day";
              default-retention-period = "3 months";
            };

            chunking = {
              nar-size-threshold = if builtins.elem "garage" config.swarselsystems.enabledServerModules then 0 else 64 * 1024; # garage using s3

              min-size = 16 * 1024;
              avg-size = 64 * 1024;
              max-size = 256 * 1024;
            };
          };
        };

        # we use s3 storage and hence do not need to persist this
        # environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
        #   { directory = "/var/lib/private/atticd"; }
        # ];

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

        systemd.services.atticd = lib.mkIf (builtins.elem "garage" config.swarselsystems.enabledServerModules) {
          requires = [ "garage.service" ];
          after = [ "garage.service" ];
        };

        nodes =
          let
            extraConfigLoc = ''
              client_body_timeout        600s;
              proxy_connect_timeout      600s;
              proxy_send_timeout         600s;
              proxy_read_timeout         600s;
              proxy_request_buffering    off;
            '';
          in
          {
            ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; };
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
          };

      };
    }

  ;
}
