{
  flake.modules.nixos.restic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit (config.swarselsystems.server.restic) targets;
    in
    {
      options.swarselsystems.server.restic.targets = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }: {
              options = {
                bucketName = lib.mkOption {
                  default = name;
                  type = lib.types.str;
                };
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                };
                repository = lib.mkOption {
                  type = lib.types.str;
                };
                withPostgres = lib.mkOption {
                  default = false;
                  type = lib.types.bool;
                };
              };
            }
          )
        );
      };
      config = {
        swarselsystems.enabledServerModules = [ "restic" ];
        sops = {
          secrets = lib.mkMerge (
            lib.mapAttrsToList (name: _: {
              "resticaccesskey-${name}" = { inherit sopsFile; };
              "resticpw-${name}" = { inherit sopsFile; };
              "resticsecretaccesskey-${name}" = { inherit sopsFile; };
            }) targets
          );

          templates = lib.mkMerge (
            lib.mapAttrsToList (name: _: {
              "restic-env-${name}".content = ''
                AWS_ACCESS_KEY_ID=${config.sops.placeholder."resticaccesskey-${name}"}
                AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."resticsecretaccesskey-${name}"}
              '';
            }) targets
          );
        };
        services.restic.backups = lib.mapAttrs' (
          name: target:
          let
            postgresDumpDir = "/var/backup/restic-${name}";
          in
          lib.nameValuePair target.bucketName {
            inherit (target) repository;
            backupPrepareCommand = ''
              set -euo pipefail
            ''
            + lib.optionalString target.withPostgres ''
              ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root ${postgresDumpDir}
              ${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dumpall --clean --if-exists > ${postgresDumpDir}/dumpall.sql
              ${pkgs.coreutils}/bin/chmod 0600 ${postgresDumpDir}/dumpall.sql
            ''
            + ''
              ${pkgs.restic}/bin/restic prune
            '';
            environmentFile = config.sops.templates."restic-env-${name}".path;
            initialize = true;
            passwordFile = config.sops.secrets."resticpw-${name}".path;
            paths = target.paths ++ lib.optional target.withPostgres postgresDumpDir;
            pruneOpts = [
              "--keep-daily 3"
              "--keep-weekly 2"
              "--keep-monthly 3"
              "--keep-yearly 100"
            ];
            timerConfig.OnCalendar = "03:00";
          }
        ) targets;
      };
    }

  ;
}
