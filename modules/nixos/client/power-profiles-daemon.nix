{ lib, config, ... }:
{
  options.swarselmodules.ppd = lib.mkEnableOption "power profiles daemon config";
  config = lib.mkIf config.swarselmodules.ppd {
    services.power-profiles-daemon.enable = true;
  };
}
