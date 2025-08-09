{ lib, config, ... }:
{
  options.swarselmodules.systemdTimeout = lib.mkEnableOption "systemd timeout config";
  config = lib.mkIf config.swarselmodules.systemdTimeout {
    # systemd
    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "60s";
      DefaultTimeoutStopSec = "15s";
    };
  };
}
