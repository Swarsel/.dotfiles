{
  flake.modules.nixos.koillection =
    {
      self,
      root,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/koillection";
          name = "koillection";
          port = 2282;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        serviceUser
        topologyContainerName
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;

      postgresUser = config.systemd.services.postgresql.serviceConfig.User;
      postgresPort = config.services.postgresql.settings.port;
      containerRev = "sha256:bb8ad2b6891441d8ec5c3169b684b71574f3bb3e9afb345bad2f91d833d60340";

    in
    {
      imports = [
        self.modules.nixos.postgresql
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems = {
          enabledServerModules = [ "koillection" ];
          server.postgresql.rolePasswordFiles.${serviceName} =
            config.sops.secrets.koillection-db-password.path;
        };
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
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
            expectedBodyRegex = "Koillection";
          };
          networks = confLib.mkDualFirewallRules {
            tcpPorts = [
              servicePort
              postgresPort
            ];
          };
        };
        sops.secrets = {
          koillection-db-password = {
            group = postgresUser;
            mode = "0440";
            owner = postgresUser;
            rekey.generator.script = "alnum";
          };
          koillection-env-file = { };
        };
        services.postgresql = {
          enable = true;
          authentication = ''
            host ${serviceName} ${serviceName} 10.88.0.0/16 scram-sha-256
          '';
          enableTCPIP = true;
          ensureDatabases = [ serviceName ];
          ensureUsers = [
            {
              ensureDBOwnership = true;
              name = serviceName;
            }
          ];
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [ { directory = "/var/lib/${serviceName}"; } ];
        };
        virtualisation.oci-containers.containers.koillection = {
          environment = {
            APP_DEBUG = "0";
            APP_ENV = "prod";
            CORS_ALLOW_ORIGIN = "https?://(localhost|${lib.escapeRegex serviceDomain})(:[0-9]+)?$";
            DB_DRIVER = "pdo_pgsql";
            DB_HOST = "host.docker.internal";
            DB_NAME = serviceName;
            # DB_PASSWORD set in koillection-env-file
            DB_PORT = "${toString postgresPort}";
            DB_USER = serviceUser;
            DB_VERSION = "16";
            HTTPS_ENABLED = "1";
            PHP_MEMORY_LIMIT = "512M";
            PHP_TZ = config.repo.secrets.common.location.timezone;
            UPLOAD_MAX_FILESIZE = "512M";
          };
          environmentFiles = [
            config.sops.secrets.koillection-env-file.path
          ];
          extraOptions = [
            "--add-host=host.docker.internal:host-gateway"
          ];
          image = "koillection/koillection@${containerRev}";
          ports = [
            "${toString servicePort}:80"
          ];
          volumes = [
            "${serviceDir}/uploads:/uploads"
          ];
        };
        nodes =
          let
            extraConfigLoc = ''
              proxy_buffer_size          128k;
              proxy_buffers              4 256k;
              proxy_busy_buffers_size    256k;
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
    };
}
