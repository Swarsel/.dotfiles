{ self, config, lib, pkgs, confLib, ... }:
let
  inherit (confLib.gen { name = "postgresql"; port = 3254; }) serviceName;
  postgresVersion = 14;
  postgresDirPrefix = "/var/lib";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    services = {
      ${serviceName} = {
        enable = true;
        package = pkgs."postgresql_${builtins.toString postgresVersion}";
        dataDir = "${postgresDirPrefix}/${serviceName}/${builtins.toString postgresVersion}";
      };
    };
    environment.persistence = {
      "/persist".directories = lib.mkIf (config.swarselsystems.isImpermanence && config.swarselsystems.isCloud) [
        { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0750"; }
      ];
      "/state".directories = lib.mkIf config.swarselsystems.isMicroVM [
        { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0750"; }
      ];
    };

  };
}
