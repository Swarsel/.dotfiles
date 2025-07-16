{ lib, config, ... }:
{
  options.swarselprofiles.btrfs = lib.mkEnableOption "is this a host using btrfs";
  config = lib.mkIf config.swarselprofiles.btrfs {
    swarselmodules = {
      optional = {
        btrfs = lib.mkDefault true;
      };
    };

  };

}
