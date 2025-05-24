{ lib, config, ... }:
{
  options.swarselsystems.modules.optional.btrfs = lib.mkEnableOption "optional btrfs settings";
  config = lib.mkIf config.swarselsystems.modules.optional.btrfs {
    boot = {
      supportedFilesystems = [ "btrfs" ];
    };
  };
}
