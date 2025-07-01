{ config, lib, pkgs, ... }:
let
  serviceName = "postgresql";
  postgresVersion = 14;
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {
    services = {
      ${serviceName} = {
        enable = true;
        package = pkgs."postgresql_${builtins.toString postgresVersion}";
        dataDir = "/Vault/data/${serviceName}/${builtins.toString postgresVersion}";
      };
    };
  };
}
