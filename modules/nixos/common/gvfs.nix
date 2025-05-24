{ lib, config, ... }:
{
  options.swarselsystems.modules.gvfs = lib.mkEnableOption "gvfs config for nautilus";
  config = lib.mkIf config.swarselsystems.modules.gvfs {
    services.gvfs.enable = true;
  };
}
