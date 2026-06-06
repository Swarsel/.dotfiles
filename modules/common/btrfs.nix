{
  flake.modules.nixos.btrfs = { lib, config, ... }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "btrfs" ];
        boot = {
          supportedFilesystems = lib.mkIf config.swarselsystems.isBtrfs [ "btrfs" ];
        };
      };
    }
  ;
}
