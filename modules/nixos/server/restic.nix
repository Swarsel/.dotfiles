{ lib, pkgs, config, ... }:
let
  inherit (config.repo.secrets.local) resticRepo;
in
{
  options.swarselsystems.modules.server.restic = lib.mkEnableOption "enable restic backups on server";
  config = lib.mkIf config.swarselsystems.modules.server.restic {

    sops = {
      secrets = {
        resticpw = { };
        resticaccesskey = { };
        resticsecretaccesskey = { };
      };
      templates = {
        "restic-env".content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.resticaccesskey}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.resticsecretaccesskey}
        '';
      };
    };

    services.restic = {
      backups = {
        SwarselWinters = {
          environmentFile = config.sops.templates."restic-env".path;
          passwordFile = config.sops.secrets.resticpw.path;
          paths = [
            "/Vault/data/paperless"
            "/Vault/Eternor/Paperless"
            "/Vault/Eternor/Bilder"
            "/Vault/Eternor/Immich"
          ];
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
