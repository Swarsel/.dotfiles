{ lib, config, ... }:
{
  options.swarselsystems.profiles.btrfs = lib.mkEnableOption "is this a host using btrfs";
  config = lib.mkIf config.swarselsystems.profiles.btrfs {
    swarselsystems.modules = {
      optional = {
        btrfs = lib.mkDefault true;
      };
    };

  };

}
