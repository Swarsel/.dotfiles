{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "koillection"; port = 2282; dir = "/var/lib/koillection"; }) servicePort serviceName serviceUser serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy dnsServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
  serviceDB = "koillection";

  postgresUser = config.systemd.services.postgresql.serviceConfig.User; # postgres
  postgresPort = config.services.postgresql.settings.port; # 5432
  containerRev = "sha256:96693e41a6eb2aae44f96033a090378270f024ddf4e6095edf8d57674f21095d";

  inherit (config.swarselsystems) sopsFile;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselmodules.server = {
      podman = true;
      postgresql = true;
    };

    sops.secrets = {
      koillection-db-password = { inherit sopsFile; owner = postgresUser; group = postgresUser; mode = "0440"; };
      koillection-env-file = { inherit sopsFile; };
    };

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort postgresPort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort postgresPort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; }];
    };

    virtualisation.oci-containers.containers = {
      koillection = {
        image = "koillection/koillection@${containerRev}";

        ports = [
          "${toString servicePort}:80"
        ];

        volumes = [
          "${serviceDir}/uploads:/uploads"
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

    # networking.firewall.allowedTCPPorts = [ servicePort postgresPort ];

    systemd.services.postgresql.postStart =
      let
        passwordPath = config.sops.secrets.koillection-db-password.path;
      in
      ''
        ${config.services.postgresql.package}/bin/psql -tA <<'EOF'
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

    nodes =
      let
        extraConfigLoc = ''
          proxy_buffer_size          128k;
          proxy_buffers              4 256k;
          proxy_busy_buffers_size    256k;
        '';
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; };
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
      };


  };
}
