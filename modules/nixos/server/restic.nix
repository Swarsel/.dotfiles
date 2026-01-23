{ lib, pkgs, config, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (config.swarselsystems.server.restic) targets;
in
{
  options.swarselmodules.server.restic = lib.mkEnableOption "enable restic backups on server";
  options.swarselsystems.server.restic = {
    targets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          bucketName = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          repository = lib.mkOption {
            type = lib.types.str;
          };
          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
          };
          withPostgres = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      }));
      default = { };
    };
  };

  config = lib.mkIf config.swarselmodules.server.restic {

    sops = {
      secrets =
        lib.mkMerge (lib.mapAttrsToList
          (name: _: {
            "resticpw-${name}" = { inherit sopsFile; };
            "resticaccesskey-${name}" = { inherit sopsFile; };
            "resticsecretaccesskey-${name}" = { inherit sopsFile; };
          })
          targets);

      templates =
        lib.mkMerge (lib.mapAttrsToList
          (name: _: {
            "restic-env-${name}".content = ''
              AWS_ACCESS_KEY_ID=${config.sops.placeholder."resticaccesskey-${name}"}
              AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."resticsecretaccesskey-${name}"}
            '';
          })
          targets);
    };

    services.restic.backups =
      lib.mapAttrs'
        (name: target:
          lib.nameValuePair target.bucketName {
            environmentFile =
              config.sops.templates."restic-env-${name}".path;

            passwordFile =
              config.sops.secrets."resticpw-${name}".path;

            inherit (target) paths repository;

            pruneOpts = [
              "--keep-daily 3"
              "--keep-weekly 2"
              "--keep-monthly 3"
              "--keep-yearly 100"
            ];

            backupPrepareCommand = ''
              ${pkgs.restic}/bin/restic prune
            '';

            initialize = true;

            timerConfig = {
              OnCalendar = "03:00";
            };
          }
        )
        targets;
  };
}
