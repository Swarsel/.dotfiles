{
  flake.modules.nixos.btrfs =
    { config, lib, ... }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "btrfs" ];
        boot.supportedFilesystems = lib.mkIf config.swarselsystems.isBtrfs [ "btrfs" ];
      };
    };
}
