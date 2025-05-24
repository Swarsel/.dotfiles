{ lib, config, inputs, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  resticRepo = lib.swarselsystems.getSecret "${secretsDirectory}/restic/wintersRepo";
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
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.resicsecretaccesskey}
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
            "/Vault/data/paperless"
            "/Vault/Eternor/Bilder"
            "/Vault/Eternor/Immich"
          ];
          repository = "${resticRepo}";
          initialize = true;
          timerConfig = {
            OnCalendar = "19:00";
          };
        };

      };
    };

  };
}
