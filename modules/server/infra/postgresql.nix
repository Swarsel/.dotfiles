{
  flake.modules.nixos.postgresql =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "postgresql";
          port = 3254;
        })
        serviceName
        ;
      postgresVersion = config.swarselsystems.server.postgresql.version;
      postgresDirPrefix = "/var/lib";
    in
    {
      options.swarselsystems.server.postgresql.version = lib.mkOption {
        default = 18;
        type = lib.types.int;
      };
      config = {
        swarselsystems.enabledServerModules = [ "postgresql" ];
        globals.monitoring.tcp = confLib.mkTcpMonitoring {
          serviceName = "${serviceName}-${config.node.name}";
          servicePort = config.services.${serviceName}.settings.port;
        };
        services = {
          ${serviceName} = {
            enable = true;
            package = pkgs."postgresql_${builtins.toString postgresVersion}";
            dataDir = "${postgresDirPrefix}/${serviceName}/${builtins.toString postgresVersion}";
            settings = {
              synchronous_commit = "off";
            }
            // (
              if config.swarselsystems.isMicroVM then
                {
                  effective_cache_size = "${builtins.toString (config.microvm.mem / 2)}MB";
                  shared_buffers = "${builtins.toString (config.microvm.mem / 4)}MB";
                }
              else
                { shared_buffers = "128MB"; }
            );
          };
        };
        environment.persistence = {
          "/persist".directories =
            lib.mkIf (config.swarselsystems.isImpermanence && config.swarselsystems.isCloud)
              [
                {
                  directory = "/var/lib/postgresql";
                  group = "postgres";
                  mode = "0750";
                  user = "postgres";
                }
              ];
          "/state".directories = lib.mkIf config.swarselsystems.isMicroVM [
            {
              directory = "/var/lib/postgresql";
              group = "postgres";
              mode = "0750";
              user = "postgres";
            }
          ];
        };

      };
    }

  ;
}
