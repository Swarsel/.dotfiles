{ lib, config, ... }:
{
  options.swarselmodules.btrfs = lib.mkEnableOption "optional btrfs settings";
  config = lib.mkIf config.swarselmodules.btrfs {
    boot = {
      supportedFilesystems = lib.mkIf config.swarselsystems.isBtrfs [ "btrfs" ];
    };
  };
}
