{ lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.restic {

    # TODO

  };
}
