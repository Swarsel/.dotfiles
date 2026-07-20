{
  flake.modules.nixos.systemd.config.systemd.settings.Manager = {
    DefaultTimeoutStartSec = "60s";
    DefaultTimeoutStopSec = "15s";
  };
}
