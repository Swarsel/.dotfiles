{ config, lib, pkgs, ... }:
let
  serviceName = "postgresql";
  postgresVersion = 14;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    services = {
      ${serviceName} = {
        enable = true;
        package = pkgs."postgresql_${builtins.toString postgresVersion}";
        dataDir = "/Vault/data/${serviceName}/${builtins.toString postgresVersion}";
      };
    };
  };
}
