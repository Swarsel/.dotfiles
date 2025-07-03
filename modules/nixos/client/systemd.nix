{ lib, config, ... }:
{
  options.swarselsystems.modules.systemdTimeout = lib.mkEnableOption "systemd timeout config";
  config = lib.mkIf config.swarselsystems.modules.systemdTimeout {
    # systemd
    systemd.extraConfig = ''
      DefaultTimeoutStartSec=60s
      DefaultTimeoutStopSec=15s
    '';
  };
}
