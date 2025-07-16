{ lib, config, ... }:
{
  options.swarselmodules.optional.btrfs = lib.mkEnableOption "optional btrfs settings";
  config = lib.mkIf config.swarselmodules.optional.btrfs {
    boot = {
      supportedFilesystems = [ "btrfs" ];
    };
  };
}
