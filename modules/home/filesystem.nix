{ lib, ... }:
{
  options.swarselsystems = {
    isBtrfs = lib.mkEnableOption "use btrfs filesystem";
  };
}
