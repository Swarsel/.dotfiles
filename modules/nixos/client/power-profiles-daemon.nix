{ lib, config, ... }:
{
  options.swarselsystems.modules.ppd = lib.mkEnableOption "power profiles daemon config";
  config = lib.mkIf config.swarselsystems.modules.ppd {
    services.power-profiles-daemon.enable = true;
  };
}
