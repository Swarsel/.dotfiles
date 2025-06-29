{ self, lib, config, ... }:
let
  serviceDomain = "swag.swarsel.win";
  serviceUser = "koillection";
  serviceDB = "koillection";
  serviceName = "koillection";
  servicePort = 2282;
  postgresUser = config.systemd.services.postgresql.serviceConfig.User; # postgres
  postgresPort = config.services.postgresql.settings.port; # 5432
  containerRev = "sha256:96693e41a6eb2aae44f96033a090378270f024ddf4e6095edf8d57674f21095d";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    sops.secrets = {
      koillection-db-password = { owner = postgresUser; group = postgresUser; mode = "0440"; };
      koillection-env-file = { };
    };

    topology.self.services.koillection = {
      name = "Koillection";
      info = "https://${serviceDomain}";
      icon = "${self}/topology/images/koillection.png";
    };
    globals.services.${serviceName}.domain = serviceDomain;

    virtualisation.oci-containers.containers = {
      koillection = {
        image = "koillection/koillection@${containerRev}";

        ports = [
          "${toString servicePort}:80"
        ];

        environment = {
          APP_DEBUG = "0";
          APP_ENV = "prod";
          HTTPS_ENABLED = "1";
          UPLOAD_MAX_FILESIZE = "512M";
          PHP_MEMORY_LIMIT = "512M";
          PHP_TZ = config.repo.secrets.common.location.timezone;

          CORS_ALLOW_ORIGIN = "https?://(localhost|swag\\.swarsel\\.win)(:[0-9]+)?$";

          DB_DRIVER = "pdo_pgsql";
          DB_NAME = serviceDB;
          DB_HOST = "host.docker.internal";
          DB_USER = serviceUser;
          # DB_PASSWORD set in koillection-env-file
          DB_PORT = "${toString postgresPort}";
          DB_VERSION = "16";
        };

        environmentFiles = [
          config.sops.secrets.koillection-env-file.path
        ];

        extraOptions = [
          "--add-host=host.docker.internal:host-gateway" # podman
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort postgresPort ];

    systemd.services.postgresql.postStart =
      let
        passwordPath = config.sops.secrets.koillection-db-password.path;
      in
      ''
        $PSQL -tA <<'EOF'
          DO $$
          DECLARE password TEXT;
          BEGIN
            password := trim(both from replace(pg_read_file('${passwordPath}'), E'\n', '''));
            EXECUTE format('ALTER ROLE ${serviceDB} WITH PASSWORD '''%s''';', password);
          END $$;
        EOF
      '';
    services = {
      postgresql = {
        enable = true;
        enableTCPIP = true;
        ensureDatabases = [ serviceDB ];
        ensureUsers = [
          {
            name = serviceDB;
            ensureDBOwnership = true;
          }
        ];
        authentication = ''
          host ${serviceDB} ${serviceDB} 10.88.0.0/16 scram-sha-256
        '';
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
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
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
            };
          };
        };
      };
    };
  };
}
