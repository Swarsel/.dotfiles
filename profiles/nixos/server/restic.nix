{ lib, config, ... }:
{
  options.swarselsystems.server.restic = lib.mkEnableOption "enable restic backups on server";
  config = lib.mkIf config.swarselsystems.server.restic {

    # TODO

  };
}
