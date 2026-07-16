{
  flake.modules.nixos.attic =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "attic";
          port = 8091;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;
      inherit (config.swarselsystems) isPublic mainUser sopsFile;
      serviceDB = "atticd";
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ "attic" ];
        topology.self.services.${serviceName} = {
          icon = "services.not-available";
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
        };
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "Attic Binary Cache";
            hostHeader = serviceDomain;
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = lib.mkIf (!isPublic) {
          secrets = {
            attic-garage-access-key = { inherit sopsFile; };
            attic-garage-secret-key = { inherit sopsFile; };
            attic-server-token = { inherit sopsFile; };
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
        services = {
          # networking.firewall.allowedTCPPorts = [ servicePort ];
          atticd = {
            enable = true;
            environmentFile = config.sops.templates."attic.env".path;
            settings = {
              allowed-hosts = [
                serviceDomain
              ];
              api-endpoint = "https://${serviceDomain}/";
              chunking = {
                avg-size = 64 * 1024;
                max-size = 256 * 1024;
                min-size = 16 * 1024;
                nar-size-threshold =
                  if builtins.elem "garage" config.swarselsystems.enabledServerModules then 0 else 64 * 1024; # garage using s3
              };
              compression = {
                level = 3;
                type = "zstd";
              };
              database.url = "postgresql:///atticd?host=/run/postgresql";
              garbage-collection = {
                default-retention-period = "3 months";
                interval = "1 day";
              };
              listen = "[::]:${builtins.toString servicePort}";
              require-proof-of-possession = false;
              storage =
                if builtins.elem "garage" config.swarselsystems.enabledServerModules then
                  {
                    bucket = serviceName;
                    # attic must be patched to never serve pre-signed s3 urls directly
                    # otherwise it will redirect clients to this localhost endpoint
                    # endpoint = "http://127.0.0.1:3900"; # garage port
                    endpoint = "https://${globals.services."garage-${config.node.name}".domain}";
                    region = mainUser;
                    type = "s3";
                  }
                else
                  {
                    path = serviceDir;
                    type = "local";
                  };
            };
          };
          # we use s3 storage and hence do not need to persist this
          # environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          #   { directory = "/var/lib/private/atticd"; }
          # ];
          postgresql = {
            enable = true;
            enableTCPIP = true;
            ensureDatabases = [ serviceDB ];
            ensureUsers = [
              {
                ensureDBOwnership = true;
                name = serviceDB;
              }
            ];
          };
        };
        systemd.services.atticd =
          lib.mkIf (builtins.elem "garage" config.swarselsystems.enabledServerModules)
            {
              after = [ "garage.service" ];
              requires = [ "garage.service" ];
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
          lib.mkMerge [
            {
              ${webProxy}.services.nginx = confLib.genNginx {
                inherit
                  extraConfigLoc
                  serviceAddress
                  serviceDomain
                  serviceName
                  servicePort
                  ;
                maxBody = 0;
              };
            }
            {
              ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                confLib.genNginx {
                  inherit
                    extraConfigLoc
                    serviceDomain
                    serviceName
                    servicePort
                    ;
                  extraConfig = nginxAccessRules;
                  maxBody = 0;
                  serviceAddress = homeServiceAddress;
                }
              );
            }
          ];

      };
    }

  ;
}
