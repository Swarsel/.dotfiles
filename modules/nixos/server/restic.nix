{ lib, config, ... }:
{
  options.swarselsystems.modules.server.restic = lib.mkEnableOption "enable restic backups on server";
  config = lib.mkIf config.swarselsystems.modules.server.restic {

    # TODO

  };
}
