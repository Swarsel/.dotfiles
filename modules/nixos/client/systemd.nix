_:
{
  config = {
    # systemd
    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "60s";
      DefaultTimeoutStopSec = "15s";
    };
  };
}
