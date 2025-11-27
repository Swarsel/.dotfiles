{ lib, pkgs, config, ... }:
let
  inherit (config.swarselsystems) sopsFile;
in
{
  options.swarselmodules.server.restic = lib.mkEnableOption "enable restic backups on server";
  options.swarselsystems.server.restic = {
    bucketName = lib.mkOption {
      type = lib.types.str;
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
  };
  config = lib.mkIf config.swarselmodules.server.restic {

    sops = {
      secrets = {
        resticpw = { inherit sopsFile; };
        resticaccesskey = { inherit sopsFile; };
        resticsecretaccesskey = { inherit sopsFile; };
      };
      templates = {
        "restic-env".content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.resticaccesskey}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.resticsecretaccesskey}
        '';
      };
    };

    services.restic =
      let
        inherit (config.repo.secrets.local) resticRepo;
      in
      {
        backups = {
          "${config.swarselsystems.server.restic.bucketName}" = {
            environmentFile = config.sops.templates."restic-env".path;
            passwordFile = config.sops.secrets.resticpw.path;
            inherit (config.swarselsystems.server.restic) paths;
            pruneOpts = [
              "--keep-daily 3"
              "--keep-weekly 2"
              "--keep-monthly 3"
              "--keep-yearly 100"
            ];
            backupPrepareCommand = ''
              ${pkgs.restic}/bin/restic prune
            '';
            repository = "${resticRepo}";
            initialize = true;
            timerConfig = {
              OnCalendar = "03:00";
            };
          };

        };
      };

  };
}
