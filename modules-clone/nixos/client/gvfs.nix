{ lib, config, ... }:
{
  options.swarselmodules.gvfs = lib.mkEnableOption "gvfs config for nautilus";
  config = lib.mkIf config.swarselmodules.gvfs {
    services.gvfs.enable = true;
  };
}
